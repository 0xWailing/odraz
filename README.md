<br/><br/><p align="center">
<img src="assets/icon/pho_icon.png" width="150">
</p>
<h3 align="center">
Whaleshot - view your photos and sync them to your own storage
</h3>

> **Whaleshot is a fork of [Pho](https://github.com/fregie/pho) by fregie.**
> The goal: keep everything the open-source edition of Pho already does, and add
> **S3-compatible storage** as a synchronization target.

## About this fork

Pho is a simple, serverless app that replaces the phone's native gallery and syncs photos to
network storage without any database or server-side component. Whaleshot keeps that design and
all existing features unchanged.

What this fork adds:

- **S3-compatible storage as a sync option** (AWS S3, MinIO, Cloudflare R2, Backblaze B2, Ceph, etc.)

S3 support is **not implemented yet** — upstream Pho has no S3 backend, and nothing in this repo
provides one today. See the [roadmap](#roadmap) for the plan.

## Features

Inherited from Pho:

* Local photo browsing
* Cloud photo browsing
* Incremental photo synchronization to the cloud
* Background periodic synchronization
* Image zoom, video upload and browsing
* No database, no server-side
* Cloud directory structure organized by date

## Supported storage

| Backend | Status |
|---|---|
| Samba (SMB) | Supported (from Pho) |
| WebDAV | Supported (from Pho) |
| NFS | Supported (from Pho) |
| S3-compatible | Planned (this fork) |

Android is the primary target. The iOS, Linux, macOS and Windows code is inherited from Pho but is not maintained or tested in this fork.

## Screenshots

<p align="left">
<img src="assets/screenshot/screenshot_local.png" width="220" alt="Local Gallery">
<img src="assets/screenshot/screenshot_cloud.png" width="220" alt="Cloud Gallery">
<img src="assets/screenshot/screenshot_sync.png" width="220" alt="Sync Page">
<img src="assets/screenshot/screenshot_view.png" width="220" alt="Photo Viewer">
</p>

## Roadmap

- [x] SMB, WebDAV and NFS sync (inherited from Pho)
- [ ] S3-compatible drive backend in the Go server (`server/drive/s3`)
- [ ] S3 settings in the app (endpoint, region, bucket, credentials, path-style addressing)
  - The bucket must be created by you beforehand and should be empty; Whaleshot does not create buckets
  - S3 credentials are stored unencrypted in the app's preferences at first
- [ ] Encrypt stored credentials (S3 and other drives) in the app
- [ ] Tests against a containerized S3 server (e.g. MinIO) in `test/docker-compose.yml`
- [ ] Keep the existing date-based object layout and `.thumbnail/` prefix on S3
- [ ] Prefix-based listing for S3 (`LIST` with prefix/delimiter) with result caching, instead of re-walking the whole date tree on every call
- [ ] Disk cache for cloud thumbnails, to cut repeat S3 requests while scrolling
- [ ] Generate thumbnails on demand for photos that were added to the bucket by other tools
- [ ] Encryption settings UI (enable, AES-256-GCM, password) for the existing server-side encryption
- [ ] Replace the iterative-MD5 key derivation with PBKDF2 or Argon2, keeping old encrypted files readable

## Build

### Requirements
- Flutter: 3.41.4 (stable), Dart: 3.11.1
- Go: 1.25 (toolchain go1.25.4)
- JDK: 17
- Android SDK: compileSdk 36
- Android NDK: used to build the embedded Go server (gomobile bind)
- protoc + plugins: protoc-gen-go@v1.27.1, protoc-gen-go-grpc@v1.1.0, protoc_plugin@21.1.2 (Dart)

### Steps
```bash
# 1. Generate protobuf code (Go + Dart stubs)
make prebuild      # install protoc plugins
make protobuf

# 2. Build the embedded Go server
make server-aar     # Android: android/app/libs/server.aar (needs gomobile)
make server-ios     # iOS: ios/Frameworks/RUN.xcframework
make server-linux   # Linux: linux/lib/run.so
make server-windows # Windows: windows/lib/run.dll

# 3. Build the Flutter app
make apk           # Android APK
make ipa           # iOS IPA

# 4. Run tests (Docker is required for the SMB/WebDAV/NFS test containers)
make test
```

> Note: `flutter run` does not build `android/app/libs/server.aar` automatically. Run
> `make server-aar` first, otherwise the Go server will not start.

## File storage logic

Files are stored using the date as the directory structure and the source file name as the
filename. A `.thumbnail` directory is created in the root directory to hold generated
thumbnails, mirroring the structure of the source files.

You can access and use your backed-up photos in any other way at any time, without depending on
this application.

```bash
├── 2022
│   ├── 07
│   │   ├── 02
│   │   │   ├── 20220702_100940.JPG
│   │   │   ├── 20220702_111416.JPG
│   │   │   └── 20220702_111508.JPG
│   │   └── 03
│   │       ├── 20220703_101923.DNG
│   │       ├── 20220703_112336.DNG
│   │       └── 20220703_112338.DNG
├── 2023
│   └── 01
│       └── 03
│           ├── 20230103_112348.JPG
│           ├── 20230103_124634.JPG
│           └── 20230103_124918.DNG
└── .thumbnail
     └── 2022
         └── 07
             ├── 02
             │   ├── 20220702_100940.JPG
             │   ├── 20220702_111416.JPG
             │   └── 20220702_111508.JPG
             └── 03
                 ├── 20220703_101923.DNG
                 ├── 20220703_112336.DNG
                 └── 20220703_112338.DNG
```

## Differences from upstream Pho

This fork is based on the open-source edition of Pho. Features that upstream ships only in its
Pro edition (parallel upload tuning, filters, Baidu Netdisk, etc.) are not part of this repository.

AES encryption is a partial case: the server-side engine (AES-256-GCM and legacy AES-128-CFB in
`server/imgmanager/encrypt.go`) and the client plumbing are present, but the settings UI to turn it
on was removed upstream. Restoring that UI is on the [roadmap](#roadmap).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and pull requests are welcome, especially for the S3
backend.

## License and credits

Released under the license in [LICENSE](LICENSE). Whaleshot is derived from
[fregie/pho](https://github.com/fregie/pho); all credit for the original application goes to its
author and contributors.
