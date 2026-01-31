#!/usr/bin/env bash
# start.sh
# 1) run a simple health HTTP server
node health.js &

# 2) start OpenClaw gateway
openclaw gateway --port $PORT
