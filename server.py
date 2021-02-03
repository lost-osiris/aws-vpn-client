#!/usr/bin/env python3

"""
Very simple HTTP server in python for logging requests
Usage::
    ./server.py [<port>]
"""
from http.server import BaseHTTPRequestHandler, HTTPServer
from cgi import FieldStorage
from urllib.parse import parse_qs
import logging

class Server(BaseHTTPRequestHandler):
    def do_POST(self):
        form = FieldStorage(
            fp=self.rfile,
            headers=self.headers,
            environ={'REQUEST_METHOD': 'POST'}
        )
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
                str(self.path), str(self.headers), form)

        saml_response = form.getvalue("SAMLResponse", None)
        if saml_response:
            with open("saml-response.txt", "w") as target:
                target.write(saml_response)

            self.wfile.write(b"<body><h3>Authentication details received, processing details. You may close this window at any time.</h3></body>") 
        else:
            self.wfile.write(b"<body><h3>Unable to get authentication details</h3></body>") 
        

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    server_address = ('127.0.0.1', 35001)
    httpd = HTTPServer(server_address, Server)
    logging.info('Starting httpd...\n')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    logging.info('Stopping httpd...\n')