package s3

import "testing"

func TestParseEndpoint(t *testing.T) {
	tests := []struct {
		name    string
		raw     string
		useSSL  bool
		host    string
		ssl     bool
		wantErr bool
	}{
		{"https scheme with trailing slash overrides useSSL", "https://s3.example.com/", false, "s3.example.com", true, false},
		{"http scheme overrides useSSL", "http://localhost:9000", true, "localhost:9000", false, false},
		{"bare host keeps useSSL true", "s3.us-west-004.backblazeb2.com", true, "s3.us-west-004.backblazeb2.com", true, false},
		{"bare host with port keeps useSSL false", "minio:9000", false, "minio:9000", false, false},
		{"empty endpoint", "", true, "", false, true},
		{"scheme only", "https://", true, "", false, true},
		{"path after host", "host/with/path", true, "", false, true},
		{"path after host with scheme", "https://host/with/path", true, "", false, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			host, ssl, err := ParseEndpoint(tt.raw, tt.useSSL)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("ParseEndpoint(%q, %v) = (%q, %v, nil), want error", tt.raw, tt.useSSL, host, ssl)
				}
				return
			}
			if err != nil {
				t.Fatalf("ParseEndpoint(%q, %v) unexpected error: %v", tt.raw, tt.useSSL, err)
			}
			if host != tt.host || ssl != tt.ssl {
				t.Fatalf("ParseEndpoint(%q, %v) = (%q, %v), want (%q, %v)", tt.raw, tt.useSSL, host, ssl, tt.host, tt.ssl)
			}
		})
	}
}

func TestObjectKey(t *testing.T) {
	tests := []struct {
		root, p, want string
	}{
		{"", "/2024/01/02/a.jpg", "2024/01/02/a.jpg"},
		{"photos", "/a.jpg", "photos/a.jpg"},
		{"/photos/", "a.jpg", "photos/a.jpg"},
		{"/photos", "/a.jpg", "photos/a.jpg"},
		{"/a//b/", "/c.jpg", "a/b/c.jpg"},
		{"", "", ""},
		{"", "/", ""},
		{"photos", "", "photos"},
	}
	for _, tt := range tests {
		if got := objectKey(tt.root, tt.p); got != tt.want {
			t.Errorf("objectKey(%q, %q) = %q, want %q", tt.root, tt.p, got, tt.want)
		}
	}
}
