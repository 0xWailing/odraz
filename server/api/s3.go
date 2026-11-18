package api

import (
	"context"
	"fmt"
	"time"

	pb "github.com/fregie/img_syncer/proto"
	"github.com/fregie/img_syncer/server/drive/s3"
)

// s3CheckTimeout bounds the connectivity check done before activating the drive.
const s3CheckTimeout = 15 * time.Second

// SetDriveS3 validates the configuration against the server (credentials and
// an existing bucket) and only then activates the drive. On failure the
// previously active drive stays in place. The bucket is never created.
func (a *api) SetDriveS3(ctx context.Context, req *pb.SetDriveS3Request) (rsp *pb.SetDriveS3Response, e error) {
	rsp = &pb.SetDriveS3Response{Success: true}
	for _, p := range []struct{ name, val string }{
		{"endpoint", req.Endpoint}, {"bucket", req.Bucket},
		{"access key", req.AccessKey}, {"secret key", req.SecretKey},
	} {
		if p.val == "" {
			rsp.Success, rsp.Message = false, fmt.Sprintf("param error: %s is empty", p.name)
			return
		}
	}
	d, err := s3.NewS3Drive(s3.Config{
		Endpoint: req.Endpoint, Region: req.Region, Bucket: req.Bucket,
		AccessKey: req.AccessKey, SecretKey: req.SecretKey, RootPrefix: req.Root,
		UseSSL: req.UseSsl, PathStyle: req.PathStyle,
	})
	if err != nil {
		rsp.Success, rsp.Message = false, fmt.Sprintf("invalid s3 configuration: %s", err.Error())
		return
	}
	cctx, cancel := context.WithTimeout(ctx, s3CheckTimeout)
	defer cancel()
	if err := d.Check(cctx); err != nil {
		rsp.Success, rsp.Message = false, fmt.Sprintf("connect to %s failed: %s", req.Endpoint, err.Error())
		return
	}
	a.im.SetDrive(d)
	return
}
