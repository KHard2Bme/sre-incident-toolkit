#!/bin/bash

# ==================================================
# generate-logs1.sh
# Creates realistic production-style logs
#
# Creates:
#  - 5 active logs
#  - 15 rotated .gz logs
#  - 15 extra loose .log files (8 older than 20 days)
# ==================================================

set -e

LOG_DIR="/var/log/app"
LINES=2000

echo "Creating realistic log environment in $LOG_DIR ..."

sudo mkdir -p "$LOG_DIR"


# --------------------------------------------------
# Log sets
# --------------------------------------------------

ACTIVE_LOGS=(
  "access.log"
  "worker.log"
  "scheduler.log"
  "payments.log"
  "auth.log"
)

EXTRA_LOG_PREFIX="service"

# --------------------------------------------------
# Generate content
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
      print strftime("%F %T"), "ERROR db timeout"
  }' | sudo tee "$file" >/dev/null
}

# --------------------------------------------------
# 1) Active logs
# --------------------------------------------------
echo "Generating active logs..."

for log in "${ACTIVE_LOGS[@]}"; do
  gen_log "$LOG_DIR/$log"
done

# --------------------------------------------------
# 2) Rotated compressed logs (.gz)
# 15 total
# 9 older than 20 days (mixed)
# 6 recent
# --------------------------------------------------
echo "Generating rotated archives..."

count=0

for log in "${ACTIVE_LOGS[@]}"; do
  for i in 1 2 3; do
    tmp="$LOG_DIR/archive/$log.$i"

    gen_log "$tmp"
    sudo gzip "$tmp"

    count=$((count+1))

    if [ $count -le 9 ]; then
      # random age between 21–35 days
      days=$((RANDOM%15+21))
      sudo touch -d "$days days ago" "$tmp.gz"
    else
      # recent files 1–5 days
      days=$((RANDOM%5+1))
      sudo touch -d "$days days ago" "$tmp.gz"
    fi
  done
done


# --------------------------------------------------
# 3) Extra loose logs (NOT rotated)
# 15 files, 8 older than 20 days
# --------------------------------------------------
echo "Generating additional service logs..."

for i in {1..15}; do
  file="$LOG_DIR/${EXTRA_LOG_PREFIX}-${i}.log"
  gen_log "$file"

  if [ "$i" -le 8 ]; then
    sudo touch -d "25 days ago" "$file"
  else
    days=$((RANDOM%3+1))
    sudo touch -d "$days days ago" "$file"
  fi
done

# --------------------------------------------------
# Summary
# --------------------------------------------------
echo
echo "✅ Done!"
echo "Contents:"
sudo ls -lh "$LOG_DIR"

echo
echo "Counts:"
echo "Active logs : 5"
echo "Rotated .gz : 15"
echo "Extra logs  : 15"
echo "Total files : $(ls $LOG_DIR | wc -l)"

echo
df -h "$LOG_DIR"

