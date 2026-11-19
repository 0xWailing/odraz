package s3

import (
	"bytes"
	"context"
	"io"
	"strings"
	"testing"
	"time"

	"github.com/fregie/img_syncer/test/testutil"
	"github.com/minio/minio-go/v7"
)

// These tests need the S3 test server from test/docker-compose.yml.
const (
	testEndpoint = "127.0.0.1:9000"
	testAccess   = "testkey"
	testSecret   = "testsecret123"
	testBucket   = "odraz-test"
)

func newTestDrive(t *testing.T, root string) *S3 {
	t.Helper()
	if err := testutil.InitS3(testEndpoint, testAccess, testSecret, testBucket); err != nil {
		t.Fatalf("init s3: %v", err)
	}
	d, err := NewS3Drive(Config{
		Endpoint: testEndpoint, Bucket: testBucket, AccessKey: testAccess,
		SecretKey: testSecret, RootPrefix: root, PathStyle: true,
	})
	if err != nil {
		t.Fatalf("new drive: %v", err)
	}
	return d
}

func TestUploadStoresTakenAtMetadata(t *testing.T) {
	d := newTestDrive(t, "storage")
	taken := time.Date(2023, 5, 6, 7, 8, 9, 0, time.UTC)
	body := []byte("photo bytes")
	if err := d.Upload("/2023/05/06/a.jpg", io.NopCloser(bytes.NewReader(body)), int64(len(body)), taken); err != nil {
		t.Fatalf("upload: %v", err)
	}
	st, err := d.cli.StatObject(context.Background(), testBucket, "storage/2023/05/06/a.jpg", minio.StatObjectOptions{})
	if err != nil {
		t.Fatalf("stat: %v", err)
	}
	var got string
	for k, v := range st.UserMetadata {
		if strings.EqualFold(k, "taken-at") {
			got = v
		}
	}
	if got != "2023-05-06T07:08:09Z" {
		t.Fatalf("taken-at metadata = %q (all: %v), want 2023-05-06T07:08:09Z", got, st.UserMetadata)
	}
}
