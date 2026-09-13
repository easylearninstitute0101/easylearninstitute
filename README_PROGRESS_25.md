# Progress 25 — Storage + File/Photo Security

Implemented private, tenant-isolated photo storage for student and teacher photos.

- Student/teacher photo buckets are private.
- Bucket limits: 2 MB; JPG/PNG/WebP only.
- Storage object read access is tenant-scoped.
- Upload/update/delete is restricted to institute managers.
- Existing public photo URLs are normalized to storage object paths.
- Frontend now stores paths and uses 1-hour signed URLs for display.
- No service-role or secret key is exposed in the frontend.
