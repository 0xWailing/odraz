# S3-compatible storage drive — design

Status: approved by the owner (2026-11-19). Scope: first release of S3 sync only (no caching work).

## Intent

Whaleshot is a fork of Pho (open-source edition). The owner wants to sync photos and videos
directly to S3-compatible providers (Backblaze B2, Amazon S3, MinIO, R2, ...), the way the
closed-source Pro edition of Pho reportedly can, but reimplemented in the open. This is built from
the S3 API and this codebase only, not by reverse-engineering the Pro app.

## Goals

- A new `StorageDrive` backend for S3-compatible endpoints, selectable next to SMB / WebDAV / NFS.
- Upload and browse photos and videos, including ranged reads for video playback.
- Same behavior as existing drives: date-based layout, `.thumbnail/` mirror, encryption (already
  handled above the drive in `ImgManager`) all work unchanged.
- Works for background sync (it reuses `initDrive()`).
- Tested against a containerized S3 server (MinIO) in the existing Docker test setup.

## Non-goals (this release)

- Listing cache, disk thumbnail cache, on-demand thumbnail generation (follow-up project).
- Encryption settings UI and key-derivation change (separate project).
- Reading buckets populated by the Pro app or other tools. The bucket is expected to be
  **empty / dedicated to Whaleshot**. This must be stated in the README.
- Multi-drive support, bucket creation, lifecycle/versioning management, iOS.

## Anti-goals

- No provider-specific hacks that break generic S3 compatibility.
- No TLS verification bypass by default (unlike the WebDAV drive's `InsecureSkipVerify`).
- Must not silently show an empty library when credentials or bucket are wrong; setup must fail
  with a clear message.

## Constraints

- One active drive at a time; drives are constructed directly in `server/api/<name>.go` (no
  registry). Interface: `StorageDrive` in `server/imgmanager/interface.go` (Upload, IsExist,
  Download, DownloadWithOffset, Delete, Range, Close).
- The Go server is bundled into the Android AAR with gomobile, so the dependency must be pure Go
  and size-conscious.
- `Range(dir, deal)` is called per directory by `ImgManager`, and existing drives return entries
  newest first by `ModTime()`.
- Drive config reaches the server over gRPC (`SetDriveX` RPC) and is persisted client-side in
  `SharedPreferences`, then re-applied by `initDrive()` in `lib/global.dart`, which the background
  sync entrypoint also calls.

## Approaches considered

| | Approach | Trade-off |
|---|---|---|
| A | `minio-go` v7 | Small, built for S3-compatible servers, simple custom endpoint / path-style options. Fewer AWS-only extras (not needed). |
| B | `aws-sdk-go-v2` | Official and complete, but heavier in the AAR, and recent versions send default checksum headers that have broken some third-party providers. |
| C | Hand-rolled signed HTTP | No dependency, but we would own signing, retries, XML. Not worth it. |

**Chosen: A (`minio-go`)**, by the owner. Listing: plain `LIST` per directory, no cache in this
release (owner's decision; cache is a follow-up).

## Design

### Go: `server/drive/s3/s3.go`

- `NewS3Drive(endpoint, region, bucket, accessKey, secretKey, rootPrefix string, useSSL, pathStyle bool)`
  builds a `minio.Client`.
- Object key = `rootPrefix` + path relative to root, with `/` separators and no leading slash.
- `Upload`: streaming `PutObject` with the known size (multipart handled by the library).
- `Download` / `DownloadWithOffset`: `GetObject`, with `SetRange(offset, -1)` for offsets; return
  the object size from `Stat`. Ranged reads must work for video.
- `IsExist`: `StatObject`, treating "not found" as `(false, nil)`.
- `Delete`: `RemoveObject`.
- `Range(dir, deal)`: `ListObjects` with prefix `dir/` and non-recursive delimiter. Common
  prefixes become directory `fs.FileInfo` entries, objects become file entries (name, size,
  `LastModified`).
- No `MkdirAll` needed: S3 has no directories. `Close` is a no-op.

### Go: API

- New proto messages and RPC `SetDriveS3` (fields: endpoint, region, bucket, access_key,
  secret_key, root, use_ssl, path_style). Regenerate Go and Dart stubs with `make protobuf`.
- `server/api/s3.go`: build the drive and **validate before swapping it in**: check the bucket
  exists and credentials work (e.g. `BucketExists` plus a one-key list). On failure return
  `success=false` with a message and do not call `SetDrive`. Only then `im.SetDrive(d)`.

### Flutter

- Add `Drive.s3` to the drive enum and its parsing (`getDrive`) in `lib/state_model.dart`.
- New `lib/storageform/s3form.dart`, modeled on `webdavform.dart`: endpoint, region, bucket, access
  key, secret key, optional root prefix, TLS toggle, path-style toggle (default on for custom
  endpoints), Save and Test connection.
- Preference keys `s3_endpoint`, `s3_region`, `s3_bucket`, `s3_access_key`, `s3_secret_key`,
  `s3_root_prefix`, `s3_use_ssl`, `s3_path_style`; add an `S3` case to `initDrive()`.
- Add S3 to the drive selector on mobile and desktop settings and to the onboarding storage step
  (builder to find every place the drive list is enumerated).
- Localization strings in `app_en.arb` (English only, see decision 5), then regenerate.

### Tests and docs

- Add a MinIO service (with healthcheck and a pre-created bucket) to `test/docker-compose.yml`.
- Add `TestS3()` to `server/drive/drive_test.go`, reusing the shared `testDrive()` helper.
- Add a Go test for `SetDriveS3` validation failures (bad credentials, missing bucket).
- README: move S3 from "planned" to supported when done; document the empty / dedicated bucket
  requirement, the config fields, and a short B2 / AWS / MinIO setup note.
- Update `server/drive/AGENTS.md` for the fourth drive.

## Decisions on open points

1. **Photo timestamps (owner):** S3 cannot set an object's modification time, so listing uses
   `LastModified` (upload time). `Upload` also stores the original photo time as user metadata on
   the object, so it is preserved if the file is downloaded or processed outside the app.
2. **TLS (my call, owner had no objection):** verification on by default, with an explicit
   plain-HTTP toggle for local MinIO. No "skip verification" option in this release, so a
   self-signed `https` endpoint is not supported (use `http` or a valid certificate).
3. **Secrets (owner):** stored in plain text in `SharedPreferences` for now, like the SMB / WebDAV
   passwords. Encrypting stored credentials is a roadmap item.
4. **Path-style addressing (my call, owner agreed):** default on when a custom endpoint is
   entered, off for AWS.
5. **Localization (owner):** the whole app is English-only (`supportedLocales` limited to `en`;
   the Chinese files are kept but disabled). New S3 strings go in `app_en.arb` only. If
   `flutter gen-l10n` warns about untranslated zh keys, that is expected.
6. **Bucket (owner):** the user creates the bucket beforehand and it should be empty. Whaleshot
   never creates it. Setup validation checks that the bucket exists and credentials work. This is
   documented in the README and roadmap.

## Left to the builder

- Confirm how `RangeByDate` (`server/imgmanager/imgmanager.go`, around lines 647 to 760) orders
  directory entries, since S3 prefixes have no modification time, and make `Range` compatible.
- Find every place the drive list is enumerated in the UI.
- Build the AAR before and after adding `minio-go` and record the size change; if it is
  unreasonable, revisit the library choice.
- Verify `DownloadWithOffset` behavior against MinIO for video-sized objects.
