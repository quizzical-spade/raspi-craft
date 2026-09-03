#!/bin/bash
# ~/mc/scripts/config.sh
# User variables + colours

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

#-------- USER VARIABLES ---------#
LOGFILE="$HOME/mc_server.log"
SERVER_DESC_TXT="$HOME/mc/SERVER_DESCRIPTIONS.txt"
SCRIPTS_DIR="$HOME/mc/scripts"

JAVA_PIDFILE="$XDG_RUNTIME_DIR/mc/java.pid"
TUNNEL_PIDFILE="$XDG_RUNTIME_DIR/mc/tunnel.pid"
TRY_ESTABLISH_PIDFILE="$XDG_RUNTIME_DIR/mc/try_establish.pid"
