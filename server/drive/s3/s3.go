// Package s3 implements imgmanager.StorageDrive for S3-compatible object
// stores (AWS S3, Backblaze B2, MinIO, Cloudflare R2, ...) using minio-go.
package s3

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"sort"
	"strings"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// metaTakenAt is the user-metadata key that preserves the original photo time.
const metaTakenAt = "taken-at"

// Config describes an S3 connection. Endpoint may carry an http(s):// scheme,
// which overrides UseSSL. The bucket must already exist; it is never created.
type Config struct {
	Endpoint   string
	Region     string
	Bucket     string
	AccessKey  string
	SecretKey  string
	RootPrefix string
	UseSSL     bool
	PathStyle  bool
}

// S3 is a StorageDrive backed by one bucket (optionally under a key prefix).
type S3 struct {
	cli    *minio.Client
	bucket string
	root   string
}

// NewS3Drive builds the client. It does not contact the server; use Check.
func NewS3Drive(cfg Config) (*S3, error) {
	if cfg.Bucket == "" {
		return nil, errors.New("bucket is empty")
	}
	host, ssl, err := ParseEndpoint(cfg.Endpoint, cfg.UseSSL)
	if err != nil {
		return nil, err
	}
	lookup := minio.BucketLookupAuto
	if cfg.PathStyle {
		lookup = minio.BucketLookupPath
	}
	cli, err := minio.New(host, &minio.Options{
		Creds:        credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""),
		Secure:       ssl,
		Region:       cfg.Region,
		BucketLookup: lookup,
	})
	if err != nil {
		return nil, err
	}
	return &S3{cli: cli, bucket: cfg.Bucket, root: cfg.RootPrefix}, nil
}

// Check verifies that the credentials work and the bucket exists.
func (d *S3) Check(ctx context.Context) error {
	exists, err := d.cli.BucketExists(ctx, d.bucket)
	if err != nil {
		return fmt.Errorf("cannot access bucket %q: %w", d.bucket, err)
	}
	if !exists {
		return fmt.Errorf("bucket %q does not exist (create it first)", d.bucket)
	}
	lctx, cancel := context.WithCancel(ctx)
	defer cancel()
	for obj := range d.cli.ListObjects(lctx, d.bucket, minio.ListObjectsOptions{MaxKeys: 1}) {
		if obj.Err != nil {
			return fmt.Errorf("cannot list bucket %q: %w", d.bucket, obj.Err)
		}
		break
	}
	return nil
}

func (d *S3) key(p string) string { return objectKey(d.root, p) }

func (d *S3) Upload(path string, reader io.ReadCloser, size int64, lastModified time.Time) error {
	if reader == nil {
		return errors.New("reader is nil")
	}
	defer reader.Close()
	_, err := d.cli.PutObject(context.Background(), d.bucket, d.key(path), reader, size,
		minio.PutObjectOptions{UserMetadata: map[string]string{
			metaTakenAt: lastModified.UTC().Format(time.RFC3339),
		}})
	return err
}

func isNotFound(err error) bool {
	resp := minio.ToErrorResponse(err)
	return resp.StatusCode == http.StatusNotFound || resp.Code == "NoSuchKey"
}

func (d *S3) IsExist(path string) (bool, error) {
	_, err := d.cli.StatObject(context.Background(), d.bucket, d.key(path), minio.StatObjectOptions{})
	if err == nil {
		return true, nil
	}
	if isNotFound(err) {
		return false, nil
	}
	return false, err
}

func (d *S3) Download(path string) (io.ReadCloser, int64, error) {
	ctx := context.Background()
	st, err := d.cli.StatObject(ctx, d.bucket, d.key(path), minio.StatObjectOptions{})
	if err != nil {
		return nil, 0, err
	}
	obj, err := d.cli.GetObject(ctx, d.bucket, d.key(path), minio.GetObjectOptions{})
	if err != nil {
		return nil, 0, err
	}
	return obj, st.Size, nil
}

// DownloadWithOffset reads from offset to the end and returns the full object
// size. An offset beyond the object is an error (GetObject alone would only
// fail on first read); an offset equal to the size yields an empty reader.
func (d *S3) DownloadWithOffset(path string, offset int64) (io.ReadCloser, int64, error) {
	ctx := context.Background()
	st, err := d.cli.StatObject(ctx, d.bucket, d.key(path), minio.StatObjectOptions{})
	if err != nil {
		return nil, 0, err
	}
	if offset < 0 || offset > st.Size {
		return nil, 0, fmt.Errorf("offset %d out of range for object of size %d", offset, st.Size)
	}
	if offset == st.Size {
		return io.NopCloser(bytes.NewReader(nil)), st.Size, nil
	}
	opts := minio.GetObjectOptions{}
	if err := opts.SetRange(offset, st.Size-1); err != nil {
		return nil, 0, err
	}
	obj, err := d.cli.GetObject(ctx, d.bucket, d.key(path), opts)
	if err != nil {
		return nil, 0, err
	}
	return obj, st.Size, nil
}

func (d *S3) Delete(path string) error {
	err := d.cli.RemoveObject(context.Background(), d.bucket, d.key(path), minio.RemoveObjectOptions{})
	if err != nil && !isNotFound(err) {
		return err
	}
	return nil
}

// Range lists one directory level: files newest first, then sub-directories.
// A directory that does not exist yields no entries and no error.
func (d *S3) Range(dir string, deal func(fs.FileInfo) bool) error {
	prefix := d.key(dir)
	if prefix != "" {
		prefix += "/"
	}
	var files, dirs []fs.FileInfo
	for obj := range d.cli.ListObjects(context.Background(), d.bucket, minio.ListObjectsOptions{Prefix: prefix}) {
		if obj.Err != nil {
			return obj.Err
		}
		name := strings.TrimPrefix(obj.Key, prefix)
		if strings.HasSuffix(name, "/") {
			if name = strings.TrimSuffix(name, "/"); name != "" {
				dirs = append(dirs, &fileInfo{name: name, isDir: true})
			}
			continue
		}
		if name == "" {
			continue
		}
		files = append(files, &fileInfo{name: name, size: obj.Size, modTime: obj.LastModified})
	}
	sort.SliceStable(files, func(i, j int) bool { return files[i].ModTime().After(files[j].ModTime()) })
	for _, info := range append(files, dirs...) {
		if !deal(info) {
			break
		}
	}
	return nil
}

func (d *S3) Close() error { return nil }

type fileInfo struct {
	name    string
	size    int64
	modTime time.Time
	isDir   bool
}

func (f *fileInfo) Name() string       { return f.name }
func (f *fileInfo) Size() int64        { return f.size }
func (f *fileInfo) ModTime() time.Time { return f.modTime }
func (f *fileInfo) IsDir() bool        { return f.isDir }
func (f *fileInfo) Sys() any           { return nil }
func (f *fileInfo) Mode() fs.FileMode {
	if f.isDir {
		return fs.ModeDir | 0o755
	}
	return 0o644
}
