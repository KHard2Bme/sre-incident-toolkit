#!/bin/bash
# ==========================================
# triage.sh
# Lightweight SRE triage toolkit
# Collects app + system diagnostics
# Saves results to timestamped report
# ==========================================

set -euo pipefail

APP_LOG="/var/log/app/app.log"
ACCESS_LOG="/var/log/nginx/access.log"

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
REPORT="triage-report-$TIMESTAMP.csv"

# send ALL output to screen + report file
exec > >(tee -a "$REPORT") 2>&1

echo "========================================="
echo " TRIAGE REPORT"
echo " Generated: $(date)"
echo " Host: $(hostname)"
echo "========================================="
echo ""

# =================================================
# Application Errors
# =================================================
echo "========== LAST 20 APPLICATION ERRORS =========="

if [ -f "$APP_LOG" ]; then
  grep -i "error" "$APP_LOG" | tail -20 || echo "No errors found"
else
  echo "App log not found: $APP_LOG"
fi

echo ""

# =================================================
# HTTP 5xx Count
# =================================================
echo "========== HTTP 5xx RESPONSE COUNT =========="

if [ -f "$ACCESS_LOG" ]; then
  FIVE_XX=$(awk '$9 ~ /^5/' "$ACCESS_LOG" | wc -l)
  echo "Total 5xx responses: $FIVE_XX"
else
  echo "Access log not found: $ACCESS_LOG"
  FIVE_XX=0
fi

echo ""

# =================================================
# Top failing endpoints
# =================================================
echo "========== TOP FAILING ENDPOINTS =========="

if [ -f "$ACCESS_LOG" ]; then
  awk '$9 ~ /^5/ {print $7}' "$ACCESS_LOG" \
    | sort \
    | uniq -c \
    | sort -nr \
    | head -5
else
  echo "No data"
fi

echo ""

# =================================================
# System Health
# =================================================
echo "========== DISK USAGE =========="
df -h

echo ""

echo "========== MEMORY USAGE =========="
free -h

echo ""

echo "========== CPU LOAD =========="
uptime

echo ""

echo "========== SYSTEM UPTIME =========="
uptime -p

echo ""

# =================================================
# Recommendations
# =================================================
echo "========== RECOMMENDATIONS =========="

# Disk recommendation
DISK_USED=$(df / | awk 'NR==2 {gsub("%",""); print $5}')

if [ "$DISK_USED" -gt 80 ]; then
  echo "- Disk usage above 80%. Consider log cleanup or expansion."
fi

# 5xx recommendation
if [ "$FIVE_XX" -gt 50 ]; then
  echo "- High 5xx error rate detected. Check app service, DB, or upstream dependencies."
fi

# Memory recommendation
MEM_FREE=$(free | awk '/Mem:/ {print $4}')
if [ "$MEM_FREE" -lt 200000 ]; then
  echo "- Low available memory. Investigate memory leaks or scale instance."
fi

# CPU recommendation
LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | tr -d ' ')
CPU_CORES=$(nproc)

LOAD_INT=${LOAD%.*}

if [ "$LOAD_INT" -gt "$CPU_CORES" ]; then
  echo "- CPU load exceeds core count. Possible saturation."
fi

echo "- Review logs above for root cause indicators."
echo "- Restart affected services if needed: systemctl restart nginx"
echo "- Escalate if errors persist."

echo ""
echo "========================================="
echo "Report saved to: $REPORT"
echo "========================================="

