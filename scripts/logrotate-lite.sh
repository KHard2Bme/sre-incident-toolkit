#!/bin/bash
# =====================================================
# logrotate-lite.sh
# Lightweight SRE log cleanup + archival script
# Rotates logs when disk > threshold
# Compresses, uploads to S3, deletes old logs
# Creates CSV report for auditing
# =====================================================

set -euo pipefail

LOG_DIR="/var/log/app"
ARCHIVE_DIR="$LOG_DIR/archive"
REPORT_DIR="$LOG_DIR/reports"
S3_BUCKET="s3://my-sre-log-archive-bucket"
THRESHOLD=70

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
REPORT_FILE="$REPORT_DIR/logrotate-report-${TIMESTAMP}.csv"

mkdir -p "$ARCHIVE_DIR"
mkdir -p "$REPORT_DIR"

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
BEFORE_H=$(du -sh "$LOG_DIR" | awk '{print $1}')
SPACE_BEFORE=$(du -sb "$LOG_DIR" | awk '{print $1}')

FILES_ROTATED=0
FILES_UPLOADED=0
FILES_DELETED=0

echo "Size BEFORE cleanup: $BEFORE_H"
echo ""

# -----------------------------------------------------
# Remove DEBUG + rotate logs
# -----------------------------------------------------
for file in "$LOG_DIR"/*.log; do
  [ -f "$file" ] || continue

  base=$(basename "$file")

  echo "Processing $base"

  sed -i '/DEBUG/d' "$file"

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

FILES_UPLOADED=$(ls "$ARCHIVE_DIR"/*.${TIMESTAMP}.gz 2>/dev/null | wc -l || true)

echo ""

# -----------------------------------------------------
# Upload to S3
# -----------------------------------------------------
echo "Uploading archives to S3..."
aws s3 cp "$ARCHIVE_DIR" "$S3_BUCKET/$TIMESTAMP/" \
  --recursive --exclude "*" --include "*.gz" || true

echo ""

# -----------------------------------------------------
# Delete old logs + archives > 7 days
# -----------------------------------------------------
echo "Deleting logs and compressed archives older than 7 days..."

FILES_DELETED=$(find "$ARCHIVE_DIR" -type f \
  \( -name "*.log" -o -name "*.gz" -o -name "*.tar.gz" -o -name "*.tgz" \) \
  -mtime +7 | wc -l || true)

find "$ARCHIVE_DIR" -type f \
  \( -name "*.log" -o -name "*.gz" -o -name "*.tar.gz" -o -name "*.tgz" \) \
  -mtime +7 -delete


echo ""

# -----------------------------------------------------
# After size + savings
# -----------------------------------------------------
AFTER_H=$(du -sh "$LOG_DIR" | awk '{print $1}')
SPACE_AFTER=$(du -sb "$LOG_DIR" | awk '{print $1}')

SAVED=$((SPACE_BEFORE - SPACE_AFTER))
SAVED_MB=$((SAVED / 1024 / 1024))

# -----------------------------------------------------
# Summary (console)
# -----------------------------------------------------
echo "========== SUMMARY =========="
echo "Files rotated : $FILES_ROTATED"
echo "Files uploaded: $FILES_UPLOADED"
echo "Files deleted : $FILES_DELETED"
echo "Size BEFORE   : $BEFORE_H"
echo "Size AFTER    : $AFTER_H"
echo "Space saved   : ${SAVED_MB} MB"
echo "Uploaded to   : $S3_BUCKET/$TIMESTAMP/"
echo "================================"

# -----------------------------------------------------
# CSV Report
# -----------------------------------------------------
echo "Writing CSV report..."

echo "timestamp,disk_used_percent,files_rotated,files_uploaded,files_deleted,size_before,size_after,space_saved_mb,s3_path" > "$REPORT_FILE"

echo "${TIMESTAMP},${DISK_USED},${FILES_ROTATED},${FILES_UPLOADED},${FILES_DELETED},${BEFORE_H},${AFTER_H},${SAVED_MB},${S3_BUCKET}/${TIMESTAMP}/" >> "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"

echo ""
echo "Cleanup complete."

