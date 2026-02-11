#!/bin/bash
# realistic log generator for SRE labs

set -euo pipefail

LINES=${1:-2000}

APP_LOG="app.log"
ACCESS_LOG="access.log"

> "$APP_LOG"
> "$ACCESS_LOG"

echo "Generating $LINES lines..."

endpoints=(
  "/health"
  "/api/users"
  "/api/orders"
  "/api/login"
  "/api/products"
  "/api/cart"
)

for ((i=1;i<=LINES;i++)); do
  ts=$(date +"%Y-%m-%d %H:%M:%S")

  # -------------------------
  # app.log
  # -------------------------
  r=$((RANDOM%100))

  if (( r < 65 )); then
    echo "$ts INFO Request successful" >> "$APP_LOG"

  elif (( r < 85 )); then
    echo "$ts DEBUG Cache refreshed" >> "$APP_LOG"

  else
    echo "$ts ERROR Database timeout" >> "$APP_LOG"
  fi


  # -------------------------
  # access.log
  # -------------------------
  ip="10.0.$((RANDOM%5)).$((RANDOM%255))"
  ep=${endpoints[$RANDOM % ${#endpoints[@]}]}
  bytes=$((RANDOM%1500+200))
  rt="0.$((RANDOM%900+100))"

  # simulate outage on /api/orders
  if [[ "$ep" == "/api/orders" && $((RANDOM%2)) -eq 0 ]]; then
    status=502
  else
    case $((RANDOM%100)) in
      [0-79]) status=200 ;;
      [80-89]) status=404 ;;
      *) status=500 ;;
    esac
  fi

  echo "$ip - - [$ts] \"GET $ep HTTP/1.1\" $status $bytes $rt" >> "$ACCESS_LOG"
done


echo "Done!"
wc -l *.log
