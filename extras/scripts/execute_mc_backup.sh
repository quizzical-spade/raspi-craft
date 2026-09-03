#!/bin/bash
# ~/mc/scripts/execute_mc_backup.sh
# This script is called by Cron using the following crontab line:
# 50 14 * * * $HOME/mc/scripts/execute_mc_backup.sh beta
# 0 */6 * * * $HOME/mc/scripts/execute_mc_backup.sh alpha

source "$HOME/mc/scripts/config.sh"

echo >> "$LOGFILE" 2>&1
echo "$(date) - $1" >> "$LOGFILE" 2>&1

if [ -f "$JAVA_PIDFILE" ]; then
	JAVA_PID="$(cat $JAVA_PIDFILE)"
	if ps -p $JAVA_PID > /dev/null; then
		#Server is live
		echo "Disabling saving" >> "$LOGFILE" 2>&1
		screen -S mc_server -p 3 -X stuff "save-off^M"

		trap 'echo "$(date): Enabling saving" >> "$LOGFILE" 2>&1; screen -S mc_server -p 3 -X stuff "save-on^M"' EXIT

		rsnapshot "$1" > /dev/null  2>&1
		exit_code=$?
		echo "Rsnap exited with code: $exit_code" >> "$LOGFILE" 2>&1
	else
		echo "PID file found, but no Java process with matching PID, not running backup" >> "$LOGFILE" 2>&1
	fi
else
	echo "PID file not found, not running backup" >> "$LOGFILE" 2>&1
fi
