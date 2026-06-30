---
name: manage-library
description: >
  Manage your Marky content library through the API: upload media, organize folders, and
  create, read, update, or delete files (notes, briefs, knowledge-base docs). Use this when
  you want to add reference material Marky can draw on when writing posts, tidy up your
  media, or store campaign notes and plans. Reads auth and endpoints from the marky-api skill.
---

# Manage Library

Your Marky library is the knowledge base behind your content: uploaded images and video,
plus text files (briefs, notes, FAQs, brand docs) that Marky can reference when it writes
posts. This skill creates, organizes, and cleans it up through the API.

**Read the `marky-api` skill first** for the base URL, your `mk_live_` key, and the full
endpoint list. Everything below uses `https://api.mymarky.ai/api` and the header
`Authorization: Bearer mk_live_YOUR_KEY`.

## Find your business

```bash
curl https://api.mymarky.ai/api/businesses \
  -H "Authorization: Bearer mk_live_YOUR_KEY"
```

Copy the `id` you want as `BIZ_ID`.

## Upload media

Upload an image or video. Multipart form, field name `file`, up to 50 MB. The response has
an `original_url` you can attach to a post or a file.

```bash
curl -X POST "https://api.mymarky.ai/api/businesses/BIZ_ID/media" \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -F "file=@/path/to/photo.jpg"
```

## Browse what is already there

```bash
# Media library (uploaded images and video).
curl "https://api.mymarky.ai/api/businesses/BIZ_ID/library" \
  -H "Authorization: Bearer mk_live_YOUR_KEY"

# Search the library by keyword.
curl "https://api.mymarky.ai/api/businesses/BIZ_ID/library/search?query=team%20photo" \
  -H "Authorization: Bearer mk_live_YOUR_KEY"

# One media item.
curl https://api.mymarky.ai/api/businesses/BIZ_ID/library/MEDIA_ID \
  -H "Authorization: Bearer mk_live_YOUR_KEY"

# Folders and files (your text docs / knowledge base).
curl "https://api.mymarky.ai/api/businesses/BIZ_ID/folders" \
  -H "Authorization: Bearer mk_live_YOUR_KEY"

curl "https://api.mymarky.ai/api/businesses/BIZ_ID/files" \
  -H "Authorization: Bearer mk_live_YOUR_KEY"
```

## Organize with folders

```bash
# Create a folder (omit parent_id for a top-level folder).
curl -X POST https://api.mymarky.ai/api/businesses/BIZ_ID/folders \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "name": "Knowledge Base" }'

# Rename or move a folder.
curl -X PATCH https://api.mymarky.ai/api/businesses/BIZ_ID/folders/FOLDER_ID \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "name": "Brand Docs" }'

# Delete a folder.
curl -X DELETE https://api.mymarky.ai/api/businesses/BIZ_ID/folders/FOLDER_ID \
  -H "Authorization: Bearer mk_live_YOUR_KEY"
```

## Create and edit files

Files are text documents (markdown works well) stored at a `path`. Use them for briefs,
FAQs, service catalogs, brand guidelines, campaign notes, anything you want Marky to be
able to reference.

```bash
# Create a file.
curl -X POST https://api.mymarky.ai/api/businesses/BIZ_ID/library/files \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/knowledge-base/services.md",
    "content": "# Our Services\n\n- Service one...\n- Service two..."
  }'

# Read / update / delete a file.
curl https://api.mymarky.ai/api/businesses/BIZ_ID/files/FILE_ID \
  -H "Authorization: Bearer mk_live_YOUR_KEY"

curl -X PUT https://api.mymarky.ai/api/businesses/BIZ_ID/files/FILE_ID \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "content": "# Our Services (updated)\n\n..." }'

curl -X DELETE https://api.mymarky.ai/api/businesses/BIZ_ID/files/FILE_ID \
  -H "Authorization: Bearer mk_live_YOUR_KEY"
```

## Attach media to a file

Pair an uploaded image with a file (for example, a product photo with a product doc).
The body takes `media_ids` (a list, so you can attach several at once):

```bash
curl -X POST https://api.mymarky.ai/api/businesses/BIZ_ID/files/FILE_ID/media \
  -H "Authorization: Bearer mk_live_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "media_ids": ["MEDIA_ID"] }'
```

## Why this matters

A rich library is the single biggest lever for on-brand content. When you upload your real
docs (case studies, FAQs, service descriptions, brand guidelines) and uploaded photos,
Marky writes more grounded, specific posts instead of generic ones. Build the library
first, then generate with the `schedule-posts` or `plan-social-content` skill.

## Notes

- `path` is how files are organized (e.g. `/knowledge-base/services.md`). Keep a consistent
  folder structure.
- Deleting a file or media item is permanent. Confirm with the user before deleting.
