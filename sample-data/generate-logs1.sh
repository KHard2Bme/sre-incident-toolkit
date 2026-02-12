#!/bin/bash

# ==================================================
# generate-logs1.sh
# Creates realistic production-style logs for testing
# /var/log/app
#  - 5 active logs (NOT app.log)
#  - 15 rotated .gz logs
#  - 5 older than 7 days (eligible for cleanup)
# ==================================================

LOG_DIR="/var/log/app"
LINES=2000

echo "Creating realistic log environment in $LOG_DIR ..."

sudo mkdir -p "$LOG_DIR"

# --------------------------------------------------
# Active log names (NO app.log)
# --------------------------------------------------
ACTIVE_LOGS=(
  "access.log"
  "worker.log"
  "scheduler.log"
  "payments.log"
  "auth.log"
)

# --------------------------------------------------
# Function: generate random log content
# --------------------------------------------------
gen_log () {
  file=$1

  seq $LINES | awk '
  BEGIN{srand()}
  {
    r=int(rand()*100)

    if(r<60)
      print strftime("%F %T"), "INFO request ok"

    else if(r<80)
      print strftime("%F %T"), "DEBUG cache hit"

    else if(r<95)
      print strftime("%F %T"), "WARN slow query"

    else
      print strftime("%F %T"), "ERROR database timeout"
  }' | sudo tee "$file" >/dev/null
}

# --------------------------------------------------
# Create 5 active logs
# --------------------------------------------------
echo "Generating active logs..."

for log in "${ACTIVE_LOGS[@]}"; do
  gen_log "$LOG_DIR/$log"
done

# --------------------------------------------------
# Create 15 rotated compressed logs
# 5 older than 7 days
# --------------------------------------------------
echo "Generating rotated archives..."

count=0

for log in "${ACTIVE_LOGS[@]}"; do
  for i in 1 2 3; do
    tmp="$LOG_DIR/$log.$i"

    gen_log "$tmp"
    sudo gzip "$tmp"

    count=$((count+1))

    # first 5 -> old (>7 days)
    if [ $count -le 5 ]; then
      sudo touch -d "12 days ago" "$tmp.gz"
    else
      # rest recent (1–5 days old)
      days=$((RANDOM%5+1))
      sudo touch -d "$days days ago" "$tmp.gz"
    fi
  done
done

# --------------------------------------------------
# Summary
# --------------------------------------------------
echo
echo "✅ Done!"
echo "Directory contents:"
sudo ls -lh "$LOG_DIR"

echo
echo "Line counts (sample):"
for f in "$LOG_DIR"/*.log; do
  echo "$(basename $f): $(wc -l < $f) lines"
done

echo
echo "Disk usage:"
df -h "$LOG_DIR"
