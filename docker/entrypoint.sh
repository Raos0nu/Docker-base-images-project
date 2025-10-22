#!/usr/bin/env sh
set -e
if [ "$#" -gt 0 ]; then
  exec "$@"
else
  tail -f /dev/null
fi
