#!/bin/bash

# ==========================================
# generate-logs.sh
# Creates realistic large sample logs
# ==========================================

APP_LOG="app.log"
ACCESS_LOG="access.log"

LINES=2000

echo "Generating $LINES lines of logs..."

rm -f "$APP_LOG" "$ACCESS_LOG"

# -------------------------
# Helpers
# -------------------------

rand_ip() {
  echo "10.0.$((RANDOM%5)).$((RANDOM%255))"
}

rand_ms() {
  printf "0.%03d\n" $((RANDOM%900+100))
}

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

nginx_time() {
  date +"%d/%b/%Y:%H:%M:%S"
}

# -------------------------
# Generate app.log
# -------------------------

for i in $(seq 1 $LINES); do
  t=$(timestamp)

  r=$((RANDOM % 100))

  if [ $r -lt 70 ]; then
    echo "$t INFO  GET /api/products 200 40ms" >> "$APP_LOG"

  elif [ $r -lt 85 ]; then
    echo "$t DEBUG Cache refresh complete" >> "$APP_LOG"

  else
    echo "$t ERROR Database connection timeout" >> "$APP_LOG"
  fi
done

# add some startup lines
sed -i '1i 2026-01-24 13:58:01 INFO Starting myapp v2.3.1' "$APP_LOG"

# -------------------------
# Generate access.log
# -------------------------

endpoints=(
  "/health"
  "/api/users"
  "/api/orders"
  "/api/login"
  "/api/products"
)

for i in $(seq 1 $LINES); do
  ip=$(rand_ip)
  ep=${endpoints[$RANDOM % ${#endpoints[@]}]}
  time=$(nginx_time)
  rt=$(rand_ms)

  r=$((RANDOM % 100))

  if [ $r -lt 80 ]; then
    status=200
  elif [ $r -lt 90 ]; then
    status=404
  else
    status=502
  fi

  bytes=$((RANDOM % 1000 + 200))

  echo "$ip - - [$time] \"GET $ep HTTP/1.1\" $status $bytes $rt" >> "$ACCESS_LOG"
done

echo "Done!"
echo "Generated:"
echo "  $APP_LOG ($(wc -l < $APP_LOG) lines)"
echo "  $ACCESS_LOG ($(wc -l < $ACCESS_LOG) lines)"
