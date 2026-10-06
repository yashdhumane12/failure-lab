"""
Failure Lab target app — exposes endpoints to observe during chaos experiments.
"""
import os, time, socket, logging, json
from flask import Flask, jsonify
import psycopg2, redis as redis_lib

logging.basicConfig(level=logging.INFO,
    format='{"time":"%(asctime)s","level":"%(levelname)s","msg":"%(message)s"}')
log = logging.getLogger(__name__)
app = Flask(__name__)

def pg_conn():
    return psycopg2.connect(
        host=os.getenv("PGHOST","postgres"), port=5432,
        dbname=os.getenv("PGDB","appdb"),
        user=os.getenv("PGUSER","appuser"),
        password=os.getenv("PGPASS","secret"),
        connect_timeout=3)

def redis_conn():
    return redis_lib.Redis(host=os.getenv("REDIS_HOST","redis"),
                           port=6379, socket_timeout=2, decode_responses=True)

@app.route("/health")
def health():
    checks, ok = {}, True
    try:
        with pg_conn() as c, c.cursor() as cur:
            cur.execute("SELECT 1"); checks["postgres"] = "ok"
    except Exception as e:
        checks["postgres"] = str(e); ok = False
    try:
        redis_conn().ping(); checks["redis"] = "ok"
    except Exception as e:
        checks["redis"] = str(e); ok = False
    return jsonify({"status": "ok" if ok else "degraded", "checks": checks}), 200 if ok else 503

@app.route("/")
def home():
    return jsonify({"service": "failure-lab-app", "hostname": socket.gethostname()})

@app.route("/db")
def db_query():
    start = time.time()
    try:
        with pg_conn() as c, c.cursor() as cur:
            cur.execute("SELECT NOW(), version()")
            row = cur.fetchone()
        return jsonify({"time": str(row[0]), "latency_ms": round((time.time()-start)*1000,2)})
    except Exception as e:
        log.error("DB error: %s", e)
        return jsonify({"error": str(e)}), 503

@app.route("/dns")
def dns_lookup():
    target = os.getenv("DNS_TARGET","postgres")
    try:
        ip = socket.gethostbyname(target)
        return jsonify({"host": target, "resolved": ip})
    except Exception as e:
        return jsonify({"host": target, "error": str(e)}), 503

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
