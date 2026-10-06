# Incident Runbook Template

Fill this out every time you run a chaos scenario.

---

## Incident: [Scenario Name]
**Date:** YYYY-MM-DD  
**Scenario:** kill-pods / stop-db / fill-disk / break-dns / add-latency  
**Severity:** P1 / P2 / P3  

---

## 1. What did you break?
> Describe exactly what failure was introduced.
> Example: "Stopped the postgres container at 14:32"

---

## 2. What was the first symptom?
> How did you know something was wrong?
> Example: "/health returned 503 with postgres: connection refused"

---

## 3. How long until you noticed?
> If monitoring was running — when did the alert fire?
> If not — how did you find it?

---

## 4. How did you debug it?
> List the exact commands you ran.

```bash
# Example:
docker ps -a
docker logs lab-postgres
curl http://localhost:8080/health
```

---

## 5. What was the root cause?
> One sentence.
> Example: "Postgres container stopped → app DB connection pool exhausted → all /db requests returned 503"

---

## 6. How did you fix it?
```bash
# Exact commands
```

---

## 7. How long did recovery take?
> From failure → detection → fix → full recovery

---

## 8. What would have prevented this?
> Example: "A health check alert on postgres container status"

---

## 9. What did you learn?
> One or two things you understand better now.

---
