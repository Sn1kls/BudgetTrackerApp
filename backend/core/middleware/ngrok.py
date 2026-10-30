import os
import requests
from urllib.parse import urlparse


class NgrokURLMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
        self.ngrok_url = None

    def __call__(self, request):
        if not self.ngrok_url:
            try:
                res = requests.get(
                    os.getenv(
                        "NGROK_API", "http://host.docker.internal:4040/api/tunnels"
                    )
                )
                self.ngrok_url = res.json()["tunnels"][0]["public_url"]
            except Exception as e:
                print(f"Could not fetch NGROK URL: {e}")
                self.ngrok_url = "http://localhost:8000"

        parts = urlparse(self.ngrok_url)
        request.META["HTTP_HOST"] = parts.netloc
        request.META["wsgi.url_scheme"] = parts.scheme  # ✅ Працює

        response = self.get_response(request)
        return response
