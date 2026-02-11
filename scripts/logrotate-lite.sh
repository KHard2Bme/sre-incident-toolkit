#!/bin/bash
# =====================================================
# logrotate-lite.sh
# Lightweight SRE log cleanup + archival script
# Rotates logs when disk > 70%
# Compresses, uploads to S3, deletes old logs
# =====================================================

set -euo pipefail

LOG_DIR="/var/log/app"
ARCHIVE_DIR="$LOG_DIR/archive"
S3_BUCKET="s3://my-sre-log-archive-bucket"   
THRESHOLD=70

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

mkdir -p "$ARCHIVE_DIR"

echo "========== LogRotate Lite =========="
echo "Time: $(date)"
echo ""

# -----------------------------------------------------
# Disk usage check
# -----------------------------------------------------
DISK_USED=$(df / | awk 'NR==2 {gsub("%",""); print $5}')

echo "Current disk usage: ${DISK_USED}%"

if [ "$DISK_USED" -lt "$THRESHOLD" ]; then
  echo "Below threshold ($THRESHOLD%). No action needed."
  exit 0
fi

echo "Disk above threshold. Starting cleanup..."
echo ""

# -----------------------------------------------------
# Before size
# -----------------------------------------------------
BEFORE=$(du -sh "$LOG_DIR" | awk '{print $1}')
echo "Size BEFORE cleanup: $BEFORE"

SPACE_BEFORE=$(du -sb "$LOG_DIR" | awk '{print $1}')

FILES_ROTATED=0

# -----------------------------------------------------
# Remove DEBUG + rotate logs
# -----------------------------------------------------
for file in "$LOG_DIR"/*.log; do
  [ -f "$file" ] || continue

  base=$(basename "$file")

  echo "Processing $base"

  # remove DEBUG lines
  sed -i '/DEBUG/d' "$file"

  # rotate
  mv "$file" "$ARCHIVE_DIR/${base}.${TIMESTAMP}"
  touch "$file"

  FILES_ROTATED=$((FILES_ROTATED+1))
done

echo ""

# -----------------------------------------------------
# Compress rotated logs
# -----------------------------------------------------
echo "Compressing rotated logs..."
gzip "$ARCHIVE_DIR"/*.${TIMESTAMP} || true

echo ""

# -----------------------------------------------------
# Upload to S3
# Requires: AWS CLI configured
# -----------------------------------------------------
echo "Uploading archives to S3..."

aws s3 cp "$ARCHIVE_DIR" "$S3_BUCKET/$TIMESTAMP/" \
  --recursive --exclude "*" --include "*.gz"

echo ""

# -----------------------------------------------------
# Delete > 7 days old
# -----------------------------------------------------
echo "Deleting logs older than 7 days..."
find "$ARCHIVE_DIR" -type f -mtime +7 -delete

echo ""

# -----------------------------------------------------
# After size + savings
# -----------------------------------------------------
AFTER=$(du -sh "$LOG_DIR" | awk '{print $1}')
SPACE_AFTER=$(du -sb "$LOG_DIR" | awk '{print $1}')

SAVED=$((SPACE_BEFORE - SPACE_AFTER))
SAVED_MB=$((SAVED / 1024 / 1024))

# -----------------------------------------------------
# Summary
# -----------------------------------------------------
echo "========== SUMMARY =========="
echo "Files rotated: $FILES_ROTATED"
echo "Size BEFORE : $BEFORE"
echo "Size AFTER  : $AFTER"
echo "Space saved : ${SAVED_MB} MB"
echo "Uploaded to : $S3_BUCKET/$TIMESTAMP/"
echo "Retention   : 7 days"
echo "================================"
echo "Cleanup complete."
