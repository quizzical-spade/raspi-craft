#!/bin/bash
# ~/mc/scripts/is_server_running.sh
# Called by run_mc.sh when no args are passed

source "$HOME/mc/scripts/config.sh"

JAVA_PID_VALID=false
echo -n "Java PID file: "
if [ -f "$JAVA_PIDFILE" ]; then
	JAVA_PID="$(cat $JAVA_PIDFILE)"
	echo -n "found. PID = $JAVA_PID and "	
	if ps -p "$JAVA_PID" > /dev/null; then
		echo "PID is not stale."
		JAVA_PID_VALID=true
	else
		echo "PID is stale."
	fi
else
	echo "not found."
fi
echo

java_status=$(ps aux | grep -v grep | grep "$JAVA_PID")
echo -n "Java: "
if [[ "$JAVA_PID_VALID" == "true" ]]; then
	echo "$java_status"
else
	echo "Dead."
fi
echo

screen_status=$(screen -ls | grep mc)
screen_exit=$?
echo -n "Screen: "
if [ $screen_exit -eq 0 ]; then
	echo "$screen_status"
else
	echo "Dead."
fi
echo

echo "PID dir:" 
pids=""
for file in "$XDG_RUNTIME_DIR"/mc/*; do
	if [ -f "$file" ]; then
		echo "$file: $(cat $file)"
	fi
done
echo
