#!/bin/bash
# ~/mc/scriptsis_server_running.sh
# Called by run_mc_command.sh when no args are passed - ssh version

source "$HOME/mc/scripts/config.sh"
source "$HOME/mc/scripts/secrets_config.sh"

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


ssh_status=$(ps aux | grep ssh | grep @ | grep -e "-R 0.0.0.0:25565")
ssh_exit=$?
echo -n "SSH: "
if [ $ssh_exit -eq 0 ]; then
	echo "$ssh_status"
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

echo "Try_Establish: $(ps aux | grep -v "grep" | grep "try_establish_tunnel.sh" || echo "Dead.")"

echo
echo "PID dir:" 
pids=""
for file in "$XDG_RUNTIME_DIR"/mc/*; do
	if [ -f "$file" ]; then
		echo "$file: $(cat $file)"
	fi
done
echo
