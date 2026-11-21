import os
import sys
import socket
import socketserver
import shutil
import mimetypes
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, unquote

PORT = 8080
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
APK_SERVER_DIR = os.path.join(BASE_DIR, "apk_server")
DEFAULT_APK_PATH = os.path.join(APK_SERVER_DIR, "foodlink.apk")

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        return s.getsockname()[0]
    except Exception:
        return "192.168.0.144"
    finally:
        s.close()

def find_best_apk():
    """Find the best / newest APK available in the workspace."""
    candidates = [
        # Release APKs (much smaller and faster to download)
        os.path.join(BASE_DIR, "build", "app", "outputs", "flutter-apk", "app-arm64-v8a-release.apk"),
        os.path.join(BASE_DIR, "build", "app", "outputs", "flutter-apk", "app-release.apk"),
        os.path.join(BASE_DIR, "build", "app", "outputs", "apk", "release", "app-release.apk"),
        # Debug APKs
        os.path.join(BASE_DIR, "build", "app", "outputs", "flutter-apk", "app-debug.apk"),
        os.path.join(BASE_DIR, "build", "app", "outputs", "apk", "debug", "app-debug.apk"),
        # Fallback local APKs
        DEFAULT_APK_PATH,
        os.path.join(BASE_DIR, "foodlink.apk"),
    ]
    for c in candidates:
        if os.path.isfile(c) and os.path.getsize(c) > 1000000:
            return c
    return DEFAULT_APK_PATH

def sync_apk_file():
    """Ensure foodlink.apk is synced with the newest/best APK build."""
    os.makedirs(APK_SERVER_DIR, exist_ok=True)
    best = find_best_apk()
    if best and os.path.isfile(best):
        try:
            if best != DEFAULT_APK_PATH:
                shutil.copy2(best, DEFAULT_APK_PATH)
            shutil.copy2(DEFAULT_APK_PATH, os.path.join(BASE_DIR, "foodlink.apk"))
            size_mb = os.path.getsize(DEFAULT_APK_PATH) / (1024 * 1024)
            print(f"[✓] Active APK: {best} ({size_mb:.1f} MB)")
        except Exception as e:
            print(f"[!] Warning syncing APK: {e}")

class ThreadedHTTPServer(socketserver.ThreadingMixIn, HTTPServer):
    daemon_threads = True
    allow_reuse_address = True
    request_queue_size = 64

class APKHttpHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def setup(self):
        super().setup()
        # Enable TCP_NODELAY and larger send buffers for high-speed Wi-Fi streaming
        try:
            self.connection.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            self.connection.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 1024 * 1024)
            self.connection.settimeout(60.0)
        except Exception:
            pass

    def log_message(self, format, *args):
        client_host = self.client_address[0] if self.client_address else "unknown"
        sys.stdout.write(f"[{self.log_date_time_string()}] {client_host} - {format % args}\n")
        sys.stdout.flush()

    def do_HEAD(self):
        self.handle_request(send_body=False)

    def do_GET(self):
        self.handle_request(send_body=True)

    def handle_request(self, send_body=True):
        parsed = urlparse(self.path)
        path = unquote(parsed.path)

        # 1. Web Portal Landing Page
        if path in ("/", "/index.html"):
            index_path = os.path.join(APK_SERVER_DIR, "index.html")
            if not os.path.exists(index_path):
                index_path = os.path.join(BASE_DIR, "foodlink_qr_portal.html")
            self.serve_file(index_path, content_type="text/html; charset=utf-8", send_body=send_body)
            return

        # 2. QR Portal & Hub
        if path in ("/qr", "/portal", "/foodlink_qr_portal.html"):
            portal_path = os.path.join(BASE_DIR, "foodlink_qr_portal.html")
            self.serve_file(portal_path, content_type="text/html; charset=utf-8", send_body=send_body)
            return

        # 3. Direct APK Download (Redirects to high-speed cloud CDN so it never disconnects or times out)
        if path.lower().endswith(".apk") or path in ("/download", "/foodlink-apk"):
            query = parsed.query or ""
            if "local=1" not in query:
                cloud_url = "https://github.com/mustafa79996/food_donation_app/releases/latest/download/foodlink.apk"
                self.send_response(302)
                self.send_header("Location", cloud_url)
                self.send_header("Access-Control-Allow-Origin", "*")
                self.send_header("Cache-Control", "no-cache")
                self.end_headers()
                return

            apk_file = DEFAULT_APK_PATH
            if not os.path.isfile(apk_file):
                apk_file = find_best_apk()
            self.serve_apk_file(apk_file, send_body=send_body)
            return

        # 4. Static assets (images, qr codes, css, js)
        rel_path = path.lstrip("/").replace("/", os.sep)
        candidate1 = os.path.join(APK_SERVER_DIR, rel_path)
        candidate2 = os.path.join(BASE_DIR, rel_path)

        if os.path.isfile(candidate1):
            self.serve_static_file(candidate1, send_body=send_body)
        elif os.path.isfile(candidate2):
            self.serve_static_file(candidate2, send_body=send_body)
        else:
            self.send_error(404, f"File not found: {path}")

    def serve_apk_file(self, file_path, send_body=True):
        if not os.path.isfile(file_path):
            self.send_error(404, "APK file not found on server")
            return

        file_size = os.path.getsize(file_path)
        range_header = self.headers.get("Range")
        client_host = self.client_address[0] if self.client_address else "unknown"

        # Parse HTTP Range header if requested by client (Android DownloadManager / Chrome)
        if range_header and range_header.startswith("bytes="):
            try:
                byte_spec = range_header[6:].strip()
                if "," in byte_spec:
                    # Multiple ranges not supported; serve first
                    byte_spec = byte_spec.split(",")[0].strip()

                parts = byte_spec.split("-")
                if len(parts) == 2:
                    if parts[0] == "":
                        # Suffix range: bytes=-500
                        suffix_len = int(parts[1])
                        start = max(0, file_size - suffix_len)
                        end = file_size - 1
                    elif parts[1] == "":
                        # Prefix range: bytes=1000-
                        start = int(parts[0])
                        end = file_size - 1
                    else:
                        # Full range: bytes=1000-2000
                        start = int(parts[0])
                        end = int(parts[1])
                else:
                    start = 0
                    end = file_size - 1

                if start >= file_size or start > end:
                    self.send_response(416)
                    self.send_header("Content-Range", f"bytes */{file_size}")
                    self.end_headers()
                    return

                end = min(end, file_size - 1)
                content_len = end - start + 1

                self.send_response(206)
                self.send_header("Content-Type", "application/vnd.android.package-archive")
                self.send_header("Content-Disposition", 'attachment; filename="foodlink.apk"')
                self.send_header("Content-Range", f"bytes {start}-{end}/{file_size}")
                self.send_header("Content-Length", str(content_len))
                self.send_header("Accept-Ranges", "bytes")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.send_header("Cache-Control", "no-cache")
                self.end_headers()

                if send_body:
                    self.stream_file_slice(file_path, start, content_len, client_host)
                return
            except Exception as e:
                # If parsing range fails, fall through to full file
                pass

        # Full file 200 OK
        self.send_response(200)
        self.send_header("Content-Type", "application/vnd.android.package-archive")
        self.send_header("Content-Disposition", 'attachment; filename="foodlink.apk"')
        self.send_header("Content-Length", str(file_size))
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()

        if send_body:
            self.stream_file_slice(file_path, 0, file_size, client_host)

    def stream_file_slice(self, file_path, start_offset, total_bytes, client_host):
        """Stream file bytes safely, handling client disconnect/pause gracefully."""
        buffer_size = 256 * 1024  # 256KB chunks for high speed
        bytes_sent = 0
        try:
            with open(file_path, "rb") as f:
                f.seek(start_offset)
                remaining = total_bytes
                while remaining > 0:
                    read_len = min(remaining, buffer_size)
                    chunk = f.read(read_len)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    remaining -= len(chunk)
                    bytes_sent += len(chunk)
        except (ConnectionResetError, BrokenPipeError, ConnectionAbortedError, TimeoutError, socket.timeout):
            # Normal client-side pause, backgrounding, or screen lock; log quietly without crashing server
            print(f"[*] Client {client_host} paused stream ({bytes_sent / (1024*1024):.1f} MB sent). Resumable at offset {start_offset + bytes_sent}.")
        except Exception as e:
            print(f"[!] Stream error with client {client_host}: {e}")

    def serve_file(self, file_path, content_type=None, send_body=True):
        if not os.path.isfile(file_path):
            self.send_error(404, "File not found")
            return

        if not content_type:
            content_type, _ = mimetypes.guess_type(file_path)
            content_type = content_type or "application/octet-stream"

        file_size = os.path.getsize(file_path)
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(file_size))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

        if send_body:
            try:
                with open(file_path, "rb") as f:
                    shutil.copyfileobj(f, self.wfile, length=128 * 1024)
            except (ConnectionResetError, BrokenPipeError, ConnectionAbortedError):
                pass

    def serve_static_file(self, file_path, send_body=True):
        ext = os.path.splitext(file_path)[1].lower()
        if ext == ".apk":
            self.serve_apk_file(file_path, send_body=send_body)
            return

        content_types = {
            ".html": "text/html; charset=utf-8",
            ".css": "text/css; charset=utf-8",
            ".js": "application/javascript; charset=utf-8",
            ".png": "image/png",
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".svg": "image/svg+xml",
            ".ico": "image/x-icon",
            ".json": "application/json",
        }
        content_type = content_types.get(ext)
        self.serve_file(file_path, content_type=content_type, send_body=send_body)

def main():
    sync_apk_file()
    ip = get_local_ip()

    server_address = ("0.0.0.0", PORT)
    httpd = ThreadedHTTPServer(server_address, APKHttpHandler)

    print("\n" + "=" * 70)
    print("  🍲 FoodLink High-Speed Multi-Threaded APK Server is LIVE!")
    print("=" * 70)
    print(f"  • Local Wi-Fi IP:    {ip}")
    print(f"  • Listening on:      0.0.0.0:{PORT}")
    print(f"  • Direct APK Link:   http://{ip}:{PORT}/foodlink.apk")
    print(f"  • Mobile Web Portal: http://{ip}:{PORT}/")
    print(f"  • QR Code Hub:       http://{ip}:{PORT}/qr")
    if os.path.exists(DEFAULT_APK_PATH):
        size_mb = os.path.getsize(DEFAULT_APK_PATH) / (1024 * 1024)
        print(f"  • APK File Size:     {size_mb:.1f} MB ({DEFAULT_APK_PATH})")
    print("=" * 70)
    print("  ✓ Multi-threaded: handles parallel chunks & multiple devices simultaneously")
    print("  ✓ Full HTTP 206 Partial Content Range support (instant resume on disconnect)")
    print("  ✓ High-speed 256KB buffer with TCP_NODELAY optimization")
    print("  ✓ Graceful error handling for mobile screen locks & Wi-Fi fluctuation")
    print("=" * 70 + "\n")
    sys.stdout.flush()

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Server stopping...")
        httpd.server_close()
        print("[✓] Server stopped gracefully.")

if __name__ == "__main__":
    main()
