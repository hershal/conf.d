#!/usr/bin/env python3
"""Standalone static server for a plan-site report, with caching disabled so a
plain refresh always shows the latest HTML/CSS (the report is regenerated often).
Usage: ./serve.py [port]   (default 8920)"""
import http.server
import socketserver
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8920


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def log_message(self, *args):  # quiet
        pass


socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("0.0.0.0", PORT), NoCacheHandler) as httpd:
    print(f"  Report: http://localhost:{PORT}/   (no-cache; just refresh)")
    httpd.serve_forever()
