package s3

import (
	"errors"
	"fmt"
	"path"
	"path/filepath"
	"strings"
)

// ParseEndpoint normalizes a user-typed S3 endpoint to host[:port]. An explicit
// http:// or https:// scheme overrides useSSL; a bare host keeps it.
func ParseEndpoint(raw string, useSSL bool) (host string, ssl bool, err error) {
	s := strings.TrimSpace(raw)
	ssl = useSSL
	switch {
	case strings.HasPrefix(strings.ToLower(s), "https://"):
		s, ssl = s[len("https://"):], true
	case strings.HasPrefix(strings.ToLower(s), "http://"):
		s, ssl = s[len("http://"):], false
	}
	s = strings.TrimRight(s, "/")
	if s == "" {
		return "", false, errors.New("endpoint is empty")
	}
	if strings.Contains(s, "/") {
		return "", false, fmt.Errorf("endpoint %q must be a host (and optional port) without a path", raw)
	}
	return s, ssl, nil
}

// objectKey joins the configured root prefix and a drive path into an S3
// object key: forward slashes, cleaned, never starting with "/".
func objectKey(rootPrefix, p string) string {
	joined := path.Join(filepath.ToSlash(rootPrefix), filepath.ToSlash(p))
	key := strings.TrimPrefix(joined, "/")
	if key == "." { // ImgManager lists the library root as "."
		return ""
	}
	return key
}
