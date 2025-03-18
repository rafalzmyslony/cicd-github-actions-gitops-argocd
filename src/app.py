from flask import Flask, jsonify, request
from prometheus_client import Counter, generate_latest, REGISTRY
from prometheus_client import Histogram
import logging
import time

app = Flask(__name__)

# Configure logging to stdout
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)

# Define a metric for counting requests
REQUEST_COUNT = Counter(
    'flask_requests_total',
    'Total number of requests',
    ['method', 'endpoint']
)

REQUEST_LATENCY = Histogram(
    'flask_request_latency_seconds',
    'Request latency in seconds',
    ['method', 'endpoint']
)



@app.before_request
def before_request():
    request.start_time = time.time()
    REQUEST_COUNT.labels(method=request.method, endpoint=request.path).inc()
    logging.info(f"Metric incremented for {request.method} {request.path}")

@app.after_request
def after_request(response):
    latency = time.time() - request.start_time
    REQUEST_LATENCY.labels(method=request.method, endpoint=request.path).observe(latency)
    return response

@app.route("/")
def home():
    logging.info("Received request to /")
    return jsonify({"message": "Hello, World!"})

@app.route("/health")
def health():
    logging.info("Received request to /health")
    return jsonify({"status": "OK"})

@app.route('/metrics')
def metrics():
    """Expose Prometheus metrics"""
    logging.info("Received request to /metrics")
    return generate_latest(REGISTRY), 200, {'Content-Type': 'text/plain; version=0.0.4'}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
