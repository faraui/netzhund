#!/bin/sh

declare HOSTS_FILE SCAN_NAME
for ARGUMENT in "$@"; do
  case "$ARGUMENT" in
    -h|--help)
      echo "Help: Any ACM A. M. Turing Award..."
      exit 0
      ;;
    -u|--usage)
      echo "Usage: $0 [GNU or POSIX style options] [scan name] <hosts file>"
      exit 0
      ;;
    -v|--version)
      echo "Version: netzhund 1.0.0"
      exit 0
      ;;
  esac
  if [ -f "$ARGUMENT" ] && [ -z "$HOSTS_FILE" ]; then
    HOSTS_FILE="$ARGUMENT"
  else
    if [ -z "$SCAN_NAME" ]; then
      SCAN_NAME="$ARGUMENT"
    fi
  fi
done

if [ -z "$HOSTS_FILE" ]; then
  echo "Error: no hosts file passed" >&2
  echo "Usage: $0 [GNU or POSIX style options] [scan name] <hosts file>" >&2
  exit 2
fi

if ! [ -z "$SCAN_NAME" ]; then
  SCAN_NAME="$(date -I)_$SCAN_NAME"
else
  SCAN_NAME="$(date -I)"
fi

if [ -d "scans/$SCAN_NAME" ]; then
  SCAN_NAME_SUFFIX=0
  while [ -d "scans/$SCAN_NAME"_"$SCAN_NAME_SUFFIX" ]; do
    SCAN_NAME_SUFFIX=$((SCAN_NAME_SUFFIX + 1))
  done
  SCAN_NAME="$SCAN_NAME"_"$SCAN_NAME_SUFFIX"
fi

sudo echo "Scan $SCAN_NAME is initialised with $HOSTS_FILE"

while read LINE; do
  IFS=':' read -r IP PORT PROTOCOL SERVICE <<< "$LINE"
  if [[ -z "$SERVICE" ]]; then
    SERVICE="unknown"
  fi
  mkdir -p "scans/$SCAN_NAME/$SERVICE"
  echo "$IP" >> "scans/$SCAN_NAME/$SERVICE/hosts.txt"
  echo "$IP:$PORT:$PROTOCOL" >> "scans/$SCAN_NAME/$SERVICE/ports.txt"
done < $HOSTS_FILE

for SERVICE in scans/$SCAN_NAME/*/; do
  sort -o "scans/$SCAN_NAME/$SERVICE/hosts.txt" -u "scans/$SCAN_NAME/$SERVICE/hosts.txt"
  sort -o "scans/$SCAN_NAME/$SERVICE/ports.txt" -u "scans/$SCAN_NAME/$SERVICE/ports.txt"
  echo "scans/$SCAN_NAME/$SERVICE" | sudo ./scripts/$SERVICE.sh  2> >(sed "s/.*\//No script for service /; s/.sh.*//" 1>&2) &
done

wait
