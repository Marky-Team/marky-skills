#!/usr/bin/env python3
"""Local capture studio: collect the media only the user can provide — webcam
clips (with a teleprompter), screen recordings, webcam photos, screenshots.

WHY THIS EXISTS: a content plan usually needs a few things an agent can't
make — a talking-head clip, a screen demo, a real photo. Asking for them in
chat sends the user off to record somewhere and shepherd files back by hand.
This studio runs locally, records in the browser, and POSTs every capture
straight back to this server, which writes it next to tasks.json — so the
agent picks the files up the moment recording ends. Same architecture as
review-board.py: the file system is the channel, a blocking AskUserQuestion
is the clock.

Usage:
  python3 capture-studio.py tasks.json

tasks.json shape:
  {
    "title": "Clips for this week",
    "items": [
      { "id": "monday-hook",
        "kind": "talking-head" | "screen" | "photo" | "screenshot",
        "title": "Monday: 15s hook about the launch",
        "script": "Teleprompter text for video kinds (optional)",
        "note": "Framing/direction shown under the title (optional)" }
    ]
  }

Prints "STUDIO_URL: http://127.0.0.1:PORT/" on stdout, serves until the user
clicks Finish (or 60 minutes pass), then writes captures.json and exits.

Captures land in a captures/ directory next to tasks.json, named <id>.webm or
<id>.png. captures.json maps ids to those files plus any notes:
  {"captures": {"monday-hook": "captures/monday-hook.webm"},
   "notes": {"monday-hook": "best of 3 takes"}, "overall": "..."}

Only binds 127.0.0.1. Nothing is uploaded anywhere but this local server.
"""

import html
import json
import os
import re
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

IDLE_EXIT_SECONDS = 60 * 60
VIDEO_KINDS = ("talking-head", "screen")


def load_input():
    if len(sys.argv) < 2:
        sys.exit("usage: capture-studio.py tasks.json")

    path = os.path.abspath(sys.argv[1])
    with open(path) as f:
        spec = json.load(f)

    if not spec.get("items"):
        sys.exit("tasks.json has no items")

    base_dir = os.path.dirname(path)
    captures_dir = os.path.join(base_dir, "captures")
    os.makedirs(captures_dir, exist_ok=True)
    return spec, base_dir, captures_dir


def render_studio(spec):
    title = html.escape(spec.get("title") or "Capture studio")
    cards = []
    for item in spec["items"]:
        item_id = html.escape(str(item["id"]), quote=True)
        kind = item.get("kind", "talking-head")
        item_title = html.escape(item.get("title") or str(item["id"]))
        note = html.escape(item.get("note") or "")
        script = html.escape(item.get("script") or "")
        kind_label = {"talking-head": "🎥 Talking head", "screen": "🖥️ Screen recording",
                      "photo": "📷 Photo", "screenshot": "🖼️ Screenshot"}.get(kind, kind)

        cards.append(f"""
      <div class="card" id="card-{item_id}" data-id="{item_id}" data-kind="{kind}"
           data-script="{script}">
        <div class="body">
          <div class="meta">{kind_label}</div>
          <p class="caption"><strong>{item_title}</strong></p>
          {f'<p class="note">{note}</p>' if note else ''}
          <div class="stagebox" hidden>
            <video playsinline hidden></video>
            <img hidden alt="capture preview">
            <div class="prompter" hidden><p></p></div>
            <div class="recdot" hidden><i></i>REC <span class="timer">0:00</span></div>
          </div>
          <div class="controls"></div>
          <textarea placeholder="Notes for the agent (optional, e.g. 'use take 2')"
                    oninput="state.notes['{item_id}'] = this.value"></textarea>
        </div>
      </div>""")

    return f"""<!doctype html>
<html><head><meta charset="utf-8"><title>{title}</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  :root {{ color-scheme: light dark; }}
  body {{ font: 16px/1.5 -apple-system, "Segoe UI", Helvetica, Arial, sans-serif;
          margin: 0; padding: 24px; background: Canvas; color: CanvasText; }}
  h1 {{ font-size: 22px; margin: 0 0 4px; }}
  .hint {{ opacity: .7; margin: 0 0 20px; }}
  .grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(360px, 1fr)); gap: 20px; }}
  .card {{ border: 1px solid color-mix(in srgb, CanvasText 15%, transparent);
           border-radius: 12px; overflow: hidden; display: flex; flex-direction: column; }}
  .card.done {{ outline: 3px solid #16a34a; }}
  .body {{ padding: 14px; display: flex; flex-direction: column; gap: 10px; }}
  .meta {{ font-size: 13px; opacity: .65; }}
  .caption {{ margin: 0; }}
  .note {{ margin: 0; font-size: 14px; opacity: .75; }}
  .stagebox {{ position: relative; border-radius: 10px; overflow: hidden; background: #000; }}
  .stagebox video, .stagebox img {{ width: 100%; display: block; }}
  .stagebox video.mirror {{ transform: scaleX(-1); }}
  .prompter {{ position: absolute; inset: 0; pointer-events: none; display: flex;
               align-items: flex-end; padding: 14px; }}
  .prompter p {{ color: #fff; font-size: 22px; line-height: 1.4; font-weight: 700;
                 text-shadow: 0 2px 10px rgba(0,0,0,.9); margin: 0; will-change: transform; }}
  .recdot {{ position: absolute; top: 10px; left: 10px; display: flex; align-items: center;
             gap: 7px; background: rgba(0,0,0,.55); color: #fff; padding: 4px 10px;
             border-radius: 20px; font-size: 12px; }}
  .recdot i {{ width: 9px; height: 9px; border-radius: 50%; background: #ff4d6d;
               animation: blink 1s infinite; }}
  @keyframes blink {{ 50% {{ opacity: .25; }} }}
  .controls {{ display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }}
  button {{ font: inherit; padding: 8px 14px; border-radius: 8px; border: 1px solid transparent; cursor: pointer; }}
  .primary {{ background: #16a34a; color: white; }}
  .stop {{ background: #dc2626; color: white; }}
  .ghost {{ background: transparent; border-color: color-mix(in srgb, CanvasText 30%, transparent); color: CanvasText; }}
  textarea {{ font: inherit; padding: 8px; border-radius: 8px; min-height: 40px; width: 100%; box-sizing: border-box; }}
  .footer {{ position: sticky; bottom: 0; margin-top: 24px; padding: 16px 0;
             background: Canvas; border-top: 1px solid color-mix(in srgb, CanvasText 15%, transparent);
             display: flex; gap: 12px; align-items: center; }}
  .footer textarea {{ flex: 1; min-height: 44px; }}
  .submit {{ background: #2563eb; color: white; font-weight: 600; padding: 12px 22px; }}
  .done-msg {{ font-size: 18px; padding: 60px; text-align: center; }}
</style></head>
<body>
<h1>{title}</h1>
<p class="hint">Record each item — captures save automatically as you finish them.
Nothing leaves this machine except to your agent. Click Finish when done.</p>
<div class="grid">{''.join(cards)}
</div>
<div class="footer">
  <textarea id="overall" placeholder="Overall notes (optional)"></textarea>
  <button class="submit" onclick="finish()">Finish</button>
</div>
<script>
const state = {{ captures: {{}}, notes: {{}} }};

document.querySelectorAll('.card').forEach(setupCard);

function setupCard(card) {{
  const kind = card.dataset.kind;
  const controls = card.querySelector('.controls');
  if (kind === 'talking-head') {{
    addBtn(controls, 'Start camera', 'ghost', () => startCamera(card, true));
  }} else if (kind === 'screen') {{
    addBtn(controls, 'Record screen', 'primary', () => recordScreen(card));
  }} else if (kind === 'photo') {{
    addBtn(controls, 'Start camera', 'ghost', () => startCamera(card, false));
  }} else if (kind === 'screenshot') {{
    addBtn(controls, 'Grab screenshot', 'primary', () => grabScreenshot(card));
  }}
}}

function addBtn(parent, label, cls, onclick) {{
  const b = document.createElement('button');
  b.textContent = label; b.className = cls; b.onclick = onclick;
  parent.appendChild(b);
  return b;
}}

function clearControls(card) {{ card.querySelector('.controls').innerHTML = ''; }}

// --- talking head + photo share a live camera preview ---
async function startCamera(card, withAudio) {{
  const video = card.querySelector('video');
  const stream = await navigator.mediaDevices.getUserMedia({{
    video: {{ facingMode: 'user' }}, audio: withAudio }});
  card.querySelector('.stagebox').hidden = false;
  video.hidden = false; video.muted = true; video.srcObject = stream;
  video.classList.add('mirror'); video.play();
  clearControls(card);
  const controls = card.querySelector('.controls');
  if (withAudio) {{
    addBtn(controls, 'Record', 'primary', () => recordStream(card, stream));
  }} else {{
    addBtn(controls, 'Snap photo', 'primary', () => snapPhoto(card, video, stream));
  }}
  addBtn(controls, 'Stop camera', 'ghost', () => {{
    stream.getTracks().forEach(t => t.stop());
    card.querySelector('.stagebox').hidden = true;
    clearControls(card); setupCard(card);
  }});
}}

async function recordScreen(card) {{
  const stream = await navigator.mediaDevices.getDisplayMedia({{ video: true, audio: true }});
  const video = card.querySelector('video');
  card.querySelector('.stagebox').hidden = false;
  video.hidden = false; video.muted = true; video.srcObject = stream;
  video.classList.remove('mirror'); video.play();
  recordStream(card, stream);
}}

function recordStream(card, stream) {{
  const rec = new MediaRecorder(stream);
  const chunks = [];
  rec.ondataavailable = e => chunks.push(e.data);
  rec.onstop = async () => {{
    stream.getTracks().forEach(t => t.stop());
    stopPrompter(card); showRec(card, false);
    await upload(card, new Blob(chunks, {{ type: 'video/webm' }}), 'webm');
  }};

  startPrompter(card); showRec(card, true);
  clearControls(card);
  addBtn(card.querySelector('.controls'), 'Stop + save', 'stop', () => rec.stop());
  rec.start();
}}

function snapPhoto(card, video, stream) {{
  const c = document.createElement('canvas');
  c.width = video.videoWidth; c.height = video.videoHeight;
  const ctx = c.getContext('2d');
  ctx.translate(c.width, 0); ctx.scale(-1, 1);  // un-mirror the saved photo
  ctx.drawImage(video, 0, 0);
  stream.getTracks().forEach(t => t.stop());
  c.toBlob(b => {{ showStill(card, c); upload(card, b, 'png'); }}, 'image/png');
}}

async function grabScreenshot(card) {{
  const stream = await navigator.mediaDevices.getDisplayMedia({{ video: true }});
  const video = document.createElement('video');
  video.srcObject = stream; await video.play();
  const c = document.createElement('canvas');
  c.width = video.videoWidth; c.height = video.videoHeight;
  c.getContext('2d').drawImage(video, 0, 0);
  stream.getTracks().forEach(t => t.stop());
  c.toBlob(b => {{ showStill(card, c); upload(card, b, 'png'); }}, 'image/png');
}}

function showStill(card, canvas) {{
  card.querySelector('.stagebox').hidden = false;
  card.querySelector('video').hidden = true;
  const img = card.querySelector('img');
  img.src = canvas.toDataURL('image/png'); img.hidden = false;
}}

// --- teleprompter + rec indicator ---
let prompterTimer = null;
function startPrompter(card) {{
  const text = card.dataset.script;
  if (!text) return;
  const box = card.querySelector('.prompter');
  const p = box.querySelector('p');
  p.textContent = text; box.hidden = false;
  let y = 0;
  prompterTimer = setInterval(() => {{ y -= 0.5; p.style.transform = `translateY(${{y}}px)`; }}, 33);
}}
function stopPrompter(card) {{
  clearInterval(prompterTimer);
  card.querySelector('.prompter').hidden = true;
}}
function showRec(card, on) {{
  const dot = card.querySelector('.recdot');
  dot.hidden = !on;
  if (on) {{
    const t0 = Date.now();
    dot.dataset.timer = setInterval(() => {{
      const s = Math.floor((Date.now() - t0) / 1000);
      card.querySelector('.timer').textContent = `${{Math.floor(s/60)}}:${{String(s%60).padStart(2,'0')}}`;
    }}, 500);
  }} else {{
    clearInterval(dot.dataset.timer);
  }}
}}

// --- return channel: POST the capture back to the local server ---
async function upload(card, blob, ext) {{
  const id = card.dataset.id;
  const res = await fetch(`/api/upload?id=${{encodeURIComponent(id)}}&ext=${{ext}}`,
                          {{ method: 'POST', body: blob }});
  if (!res.ok) {{ alert('Save failed — try again.'); return; }}
  state.captures[id] = (await res.json()).path;
  card.classList.add('done');
  clearControls(card);
  addBtn(card.querySelector('.controls'), 'Redo', 'ghost', () => {{
    card.classList.remove('done'); clearControls(card); setupCard(card);
  }});
}}

async function finish() {{
  state.overall = document.getElementById('overall').value;
  await fetch('/api/finish', {{ method: 'POST',
    headers: {{ 'Content-Type': 'application/json' }},
    body: JSON.stringify(state) }});
  document.body.innerHTML = '<p class="done-msg">All saved — close this tab and go back to your agent.</p>';
}}
</script>
</body></html>"""


def main():
    spec, base_dir, captures_dir = load_input()
    page = render_studio(spec).encode()
    finished = threading.Event()
    valid_ids = {str(item["id"]) for item in spec["items"]}

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(page)

        def do_POST(self):
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)

            if self.path.startswith("/api/upload"):
                params = dict(re.findall(r"[?&]([^=]+)=([^&]*)", self.path))
                item_id = params.get("id", "")
                ext = params.get("ext", "")
                # ids come from tasks.json we wrote, but never trust a path from the wire
                if item_id not in valid_ids or ext not in ("webm", "png"):
                    self.send_response(400)
                    self.end_headers()
                    return

                rel = os.path.join("captures", f"{item_id}.{ext}")
                with open(os.path.join(base_dir, rel), "wb") as f:
                    f.write(body)

                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"path": rel}).encode())
                return

            if self.path == "/api/finish":
                with open(os.path.join(base_dir, "captures.json"), "w") as f:
                    f.write(body.decode())

                self.send_response(200)
                self.end_headers()
                finished.set()
                return

            self.send_response(404)
            self.end_headers()

        def log_message(self, *args):
            pass  # keep stdout clean for the STUDIO_URL line

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    print(f"STUDIO_URL: http://127.0.0.1:{server.server_address[1]}/", flush=True)

    threading.Thread(target=server.serve_forever, daemon=True).start()
    if finished.wait(timeout=IDLE_EXIT_SECONDS):
        print(f"CAPTURES_WRITTEN: {os.path.join(base_dir, 'captures.json')}", flush=True)
    else:
        print("STUDIO_TIMEOUT: no finish within 60 minutes", flush=True)

    server.shutdown()


if __name__ == "__main__":
    main()
