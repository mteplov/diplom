from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        response = """<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Netology DevOps Diploma</title>
</head>
<body>
    <h1>Netology DevOps Diploma</h1>
    <p>Application is running in Kubernetes.</p>
</body>
</html>
"""

        body = response.encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


server = HTTPServer(("0.0.0.0", 8080), Handler)
print("Application started on port 8080")
server.serve_forever()
