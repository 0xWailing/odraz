package api

import (
	"context"
	"net"
	"strings"
	"testing"
	"time"

	pb "github.com/fregie/img_syncer/proto"
	"github.com/fregie/img_syncer/server/drive/s3"
	"github.com/fregie/img_syncer/test/testutil"
)

const (
	apiS3Endpoint = "127.0.0.1:9000"
	apiS3Access   = "testkey"
	apiS3Secret   = "testsecret123"
	apiS3Bucket   = "odraz-test"
)

// requireS3 skips the test when the S3 test server (test/docker-compose.yml)
// is not running, so `go test ./...` does not fail without Docker.
func requireS3(t *testing.T) {
	t.Helper()
	conn, err := net.DialTimeout("tcp", apiS3Endpoint, time.Second)
	if err != nil {
		t.Skipf("S3 test server not reachable at %s: %v", apiS3Endpoint, err)
	}
	conn.Close()
	if err := testutil.InitS3(apiS3Endpoint, apiS3Access, apiS3Secret, apiS3Bucket); err != nil {
		t.Fatalf("init s3 bucket: %v", err)
	}
}

func s3Req() *pb.SetDriveS3Request {
	return &pb.SetDriveS3Request{
		Endpoint: apiS3Endpoint, Bucket: apiS3Bucket,
		AccessKey: apiS3Access, SecretKey: apiS3Secret,
		Root: "storage", UseSsl: false, PathStyle: true,
	}
}

func assertPreviousDriveKept(t *testing.T, a *api) {
	t.Helper()
	if _, ok := a.im.Drive().(*mockDrive); !ok {
		t.Fatalf("active drive is %T, want the previous *mockDrive to stay active", a.im.Drive())
	}
}

func TestSetDriveS3_Success(t *testing.T) {
	requireS3(t)
	a := newTestAPI()
	rsp, err := a.SetDriveS3(context.Background(), s3Req())
	if err != nil || !rsp.Success {
		t.Fatalf("SetDriveS3 = (%+v, %v), want success", rsp, err)
	}
	if _, ok := a.im.Drive().(*s3.S3); !ok {
		t.Fatalf("active drive is %T, want *s3.S3", a.im.Drive())
	}
}

func TestSetDriveS3_ParamErrors(t *testing.T) {
	cases := map[string]func(r *pb.SetDriveS3Request){
		"endpoint":   func(r *pb.SetDriveS3Request) { r.Endpoint = "" },
		"bucket":     func(r *pb.SetDriveS3Request) { r.Bucket = "" },
		"access key": func(r *pb.SetDriveS3Request) { r.AccessKey = "" },
		"secret key": func(r *pb.SetDriveS3Request) { r.SecretKey = "" },
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			a := newTestAPI()
			req := s3Req()
			mutate(req)
			rsp, err := a.SetDriveS3(context.Background(), req)
			if err != nil || rsp.Success || !strings.Contains(rsp.Message, "param error") {
				t.Fatalf("SetDriveS3 = (%+v, %v), want failure with 'param error'", rsp, err)
			}
			assertPreviousDriveKept(t, a)
		})
	}
}

func TestSetDriveS3_ConnectionFailures(t *testing.T) {
	requireS3(t)
	cases := map[string]struct {
		mutate  func(r *pb.SetDriveS3Request)
		message string
	}{
		"bad credentials": {func(r *pb.SetDriveS3Request) { r.SecretKey = "wrong-secret-value" }, ""},
		"missing bucket":  {func(r *pb.SetDriveS3Request) { r.Bucket = "bucket-that-does-not-exist" }, "does not exist"},
		"unreachable":     {func(r *pb.SetDriveS3Request) { r.Endpoint = "127.0.0.1:1" }, ""},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			a := newTestAPI()
			req := s3Req()
			tc.mutate(req)
			rsp, err := a.SetDriveS3(context.Background(), req)
			if err != nil || rsp.Success || rsp.Message == "" {
				t.Fatalf("SetDriveS3 = (%+v, %v), want failure with a message", rsp, err)
			}
			if tc.message != "" && !strings.Contains(rsp.Message, tc.message) {
				t.Fatalf("message %q does not contain %q", rsp.Message, tc.message)
			}
			assertPreviousDriveKept(t, a)
		})
	}
}
