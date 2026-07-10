#!/usr/bin/env python3
"""Local review board: show posts (or design variants) in the browser, collect
the user's choices, write them to feedback.json for the agent to read.

WHY THIS EXISTS: approving a week of posts (or picking a favorite variant) in
chat means scrolling a wall of text. A browser board is faster and clearer.
The flow (borrowed from gstack's design-shotgun): the agent starts this server
in the background, gives the user the URL inside a blocking AskUserQuestion,
and when the user clicks Submit the choices land in feedback.json next to the
input file. The browser never talks to the agent — the file is the channel.

Usage:
  python3 review-board.py items.json            # approve mode (default)
  python3 review-board.py items.json --mode pick  # pick-one-variant mode

items.json shape:
  {
    "title": "This week's posts",
    "mode": "approve" | "pick",          # optional; --mode wins
    "items": [
      { "id": "post-1",
        "caption": "text shown on the card",
        "media_url": "https://... (image or video, optional)",
        "meta": "Mon 9am - instagram, linkedIn (optional subtitle)" }
    ]
  }

Prints "BOARD_URL: http://127.0.0.1:PORT/" on stdout, then serves until the
user submits (or 30 minutes pass), then writes feedback.json and exits.

feedback.json shape:
  approve mode: {"decisions": {"post-1": "approved" | "rejected"},
                 "edits": {"post-1": "the caption as the user rewrote it"},
                 "comments": {"post-1": "..."}, "overall": "...", "mode": "approve"}
  pick mode:    {"preferred": "post-1", "ratings": {"post-1": 4},
                 "comments": {...}, "overall": "...", "mode": "pick"}

Only binds 127.0.0.1. Media URLs are loaded by the user's own browser.
"""

import html
import json
import os
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

IDLE_EXIT_SECONDS = 30 * 60


def load_input():
    if len(sys.argv) < 2:
        sys.exit("usage: review-board.py items.json [--mode approve|pick]")

    path = os.path.abspath(sys.argv[1])
    with open(path) as f:
        spec = json.load(f)

    mode = spec.get("mode", "approve")
    if "--mode" in sys.argv:
        mode = sys.argv[sys.argv.index("--mode") + 1]

    if mode not in ("approve", "pick"):
        sys.exit(f"unknown mode: {mode}")

    if not spec.get("items"):
        sys.exit("items.json has no items")

    feedback_path = os.path.join(os.path.dirname(path), "feedback.json")
    return spec, mode, feedback_path


def resolve_media(spec):
    """media_url can be a local file path — browsers block file:// inside an
    http:// page, so serve local files from the board at /media/N instead."""
    local_files = {}
    for i, item in enumerate(spec["items"]):
        url = item.get("media_url") or ""
        if url and "://" not in url and os.path.isfile(os.path.expanduser(url)):
            local_files[f"/media/{i}"] = os.path.expanduser(url)
            item["media_url"] = f"/media/{i}"

    return local_files


MEDIA_TYPES = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
               ".gif": "image/gif", ".webp": "image/webp", ".mp4": "video/mp4",
               ".webm": "video/webm", ".mov": "video/quicktime"}


def media_tag(url):
    if not url:
        return ""

    safe = html.escape(url, quote=True)
    if any(ext in url.lower() for ext in (".mp4", ".webm", ".mov")):
        return f'<video src="{safe}" controls muted playsinline></video>'

    return f'<img src="{safe}" alt="post media" loading="lazy">'


def render_board(spec, mode):
    title = html.escape(spec.get("title") or "Review board")
    cards = []
    for item in spec["items"]:
        item_id = html.escape(str(item["id"]), quote=True)
        caption = html.escape(item.get("caption") or "")
        meta = html.escape(item.get("meta") or "")
        if mode == "approve":
            controls = f"""
        <div class="controls">
          <button class="approve" onclick="setDecision('{item_id}', 'approved', this)">Approve</button>
          <button class="reject" onclick="setDecision('{item_id}', 'rejected', this)">Reject</button>
        </div>"""
        else:
            stars = "".join(
                f"<span class='star' onclick=\"setRating('{item_id}', {n}, this)\">&#9733;</span>"
                for n in range(1, 6)
            )
            controls = f"""
        <div class="controls">
          <button class="approve" onclick="setPreferred('{item_id}', this)">This one</button>
          <span class="stars" data-item="{item_id}">{stars}</span>
        </div>"""

        if mode == "approve":
            # Editable in place — users fix captions directly instead of
            # describing the fix in a comment.
            caption_block = (
                f'<div class="caption" contenteditable="true" data-item="{item_id}" '
                f'oninput="setEdit(this)">{caption}</div>'
            )
            comment_placeholder = "Rules / notes (e.g. &quot;never use exclamation marks&quot;)"
        else:
            caption_block = f'<p class="caption">{caption}</p>'
            comment_placeholder = "Comments for this one (optional)"

        cards.append(f"""
      <div class="card" id="card-{item_id}">
        {media_tag(item.get('media_url'))}
        <div class="body">
          <div class="meta">{meta}</div>
          {caption_block}
          {controls}
          <textarea placeholder="{comment_placeholder}"
                    oninput="setComment('{item_id}', this.value)"></textarea>
        </div>
      </div>""")

    submit_hint = (
        "Approve or reject each post. Captions are editable — click into one and fix it. "
        "Add rules (never / always ...) in the note boxes, then submit."
        if mode == "approve"
        else "Pick your favorite, rate the rest, then submit."
    )

    return f"""<!doctype html>
<html><head><meta charset="utf-8"><title>{title}</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  :root {{ color-scheme: light dark; }}
  body {{ font: 16px/1.5 -apple-system, "Segoe UI", Helvetica, Arial, sans-serif;
          margin: 0; padding: 24px; background: Canvas; color: CanvasText; }}
  h1 {{ font-size: 22px; margin: 0 0 4px; }}
  .hint {{ opacity: .7; margin: 0 0 20px; }}
  .grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 20px; }}
  .card {{ border: 1px solid color-mix(in srgb, CanvasText 15%, transparent);
           border-radius: 12px; overflow: hidden; display: flex; flex-direction: column; }}
  .card.approved {{ outline: 3px solid #16a34a; }}
  .card.rejected {{ outline: 3px solid #dc2626; opacity: .55; }}
  .card.preferred {{ outline: 3px solid #2563eb; }}
  .card img, .card video {{ width: 100%; aspect-ratio: 4/5; object-fit: cover; display: block; }}
  .body {{ padding: 14px; display: flex; flex-direction: column; gap: 10px; flex: 1; }}
  .meta {{ font-size: 13px; opacity: .65; }}
  .caption {{ margin: 0; white-space: pre-wrap; flex: 1; }}
  .caption[contenteditable] {{ border-radius: 8px; padding: 6px; outline: 1px dashed transparent; }}
  .caption[contenteditable]:hover {{ outline-color: color-mix(in srgb, CanvasText 30%, transparent); }}
  .caption[contenteditable]:focus {{ outline: 2px solid #2563eb; }}
  .caption.edited {{ background: color-mix(in srgb, #2563eb 8%, transparent); }}
  .controls {{ display: flex; gap: 8px; align-items: center; }}
  button {{ font: inherit; padding: 8px 14px; border-radius: 8px; border: 1px solid transparent; cursor: pointer; }}
  .approve {{ background: #16a34a; color: white; }}
  .reject {{ background: transparent; border-color: #dc2626; color: #dc2626; }}
  .star {{ cursor: pointer; font-size: 22px; opacity: .35; }}
  .star.on {{ opacity: 1; color: #eab308; }}
  textarea {{ font: inherit; padding: 8px; border-radius: 8px; min-height: 44px; width: 100%; box-sizing: border-box; }}
  .footer {{ position: sticky; bottom: 0; margin-top: 24px; padding: 16px 0;
             background: Canvas; border-top: 1px solid color-mix(in srgb, CanvasText 15%, transparent);
             display: flex; gap: 12px; align-items: center; }}
  .footer textarea {{ flex: 1; min-height: 44px; }}
  .submit {{ background: #2563eb; color: white; font-weight: 600; padding: 12px 22px; }}
  .done {{ font-size: 18px; padding: 60px; text-align: center; }}
</style></head>
<body>
<h1>{title}</h1>
<p class="hint">{submit_hint}</p>
<div class="grid">{''.join(cards)}
</div>
<div class="footer">
  <textarea id="overall" placeholder="Overall notes (optional)"></textarea>
  <button class="submit" onclick="submit()">Submit</button>
</div>
<script>
const state = {{ mode: {json.dumps(mode)}, decisions: {{}}, ratings: {{}}, comments: {{}}, edits: {{}}, preferred: null }};
const originals = {{}};
document.querySelectorAll('.caption[contenteditable]').forEach(el => {{
  originals[el.dataset.item] = el.innerText;
}});

function setEdit(el) {{
  const id = el.dataset.item;
  if (el.innerText === originals[id]) {{
    delete state.edits[id];
    el.classList.remove('edited');
  }} else {{
    state.edits[id] = el.innerText;
    el.classList.add('edited');
  }}
}}

function card(id) {{ return document.getElementById('card-' + id); }}

function setDecision(id, decision, _btn) {{
  state.decisions[id] = decision;
  card(id).classList.remove('approved', 'rejected');
  card(id).classList.add(decision);
}}

function setPreferred(id, _btn) {{
  state.preferred = id;
  document.querySelectorAll('.card').forEach(c => c.classList.remove('preferred'));
  card(id).classList.add('preferred');
}}

function setRating(id, n, star) {{
  state.ratings[id] = n;
  const stars = star.parentElement.querySelectorAll('.star');
  stars.forEach((s, i) => s.classList.toggle('on', i < n));
}}

function setComment(id, text) {{ state.comments[id] = text; }}

async function submit() {{
  state.overall = document.getElementById('overall').value;
  await fetch('/api/submit', {{ method: 'POST',
    headers: {{ 'Content-Type': 'application/json' }},
    body: JSON.stringify(state) }});
  document.body.innerHTML = '<p class="done">Got it — you can close this tab and go back to your agent.</p>';
}}
</script>
</body></html>"""


def main():
    spec, mode, feedback_path = load_input()
    local_files = resolve_media(spec)
    page = render_board(spec, mode).encode()
    submitted = threading.Event()

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path in local_files:
                file_path = local_files[self.path]
                ext = os.path.splitext(file_path)[1].lower()
                self.send_response(200)
                self.send_header("Content-Type", MEDIA_TYPES.get(ext, "application/octet-stream"))
                self.end_headers()
                with open(file_path, "rb") as f:
                    self.wfile.write(f.read())
                return

            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(page)

        def do_POST(self):
            if self.path != "/api/submit":
                self.send_response(404)
                self.end_headers()
                return

            length = int(self.headers.get("Content-Length", 0))
            feedback = json.loads(self.rfile.read(length))
            with open(feedback_path, "w") as f:
                json.dump(feedback, f, indent=2)

            self.send_response(200)
            self.end_headers()
            submitted.set()

        def log_message(self, *args):
            pass  # keep stdout clean for the BOARD_URL line

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    print(f"BOARD_URL: http://127.0.0.1:{server.server_address[1]}/", flush=True)

    threading.Thread(target=server.serve_forever, daemon=True).start()
    if submitted.wait(timeout=IDLE_EXIT_SECONDS):
        print(f"FEEDBACK_WRITTEN: {feedback_path}", flush=True)
    else:
        print("BOARD_TIMEOUT: no submission within 30 minutes", flush=True)

    server.shutdown()


if __name__ == "__main__":
    main()
