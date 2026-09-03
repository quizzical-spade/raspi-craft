#!/bin/bash
# ~/create_tunnel_run_mc.sh
# run_mc.sh but will functionality for reverse tunneling.

source "$HOME/mc/scripts/config.sh"
source "$HOME/mc/scripts/secrets_config.sh"

touch "$LOGFILE"
echo >> "$LOGFILE"

log() {
    printf '%b\n' "$*" | tee -a "$LOGFILE"
}

log "$(date)"
if [ $# -gt 0 ]; then #If the number of command line args is greater than zero
	log "Running with: $@"	#Print the args we're using
fi

# Called when passing 'q' as an argument
close_tunnel () {
	log "Trying to end try_establish loop."
	if [ -f "$TRY_ESTABLISH_PIDFILE" ] && ps -p "$(cat $TRY_ESTABLISH_PIDFILE)" > /dev/null; then
		kill $(cat "$TRY_ESTABLISH_PIDFILE")
		kill_exit=$?
		if [ $kill_exit -eq 0 ]; then
			log "${GREEN}Killed try_establish loop.${ENDCOLOR}"
			rm "$TRY_ESTABLISH_PIDFILE"
		else
			log "${YELLOW}WARN: Unable to kill try_establish loop. PID file may not exist, or process within may be stale.\nCheck $TRY_ESTABLISH_PIDFILE or the comment in this file.${ENDCOLOR}"
			# kill $(ps aux | grep -E "run_mc.sh [0-9]" | grep -v grep | awk '{print $2}') 2>/dev/null
			# Kill the infinite loop by searching for open files, REGEXing for run_mc.sh and some numbers,
			# pipe the result through grep -v which selects every line that doesn't contain grep
			# (removing the original grep -E process),
			# then print the second column without printing any errors.
		fi
	else
		log "${YELLOW}WARN: try_establish loop was not running.${ENDCOLOR}"
	fi

	log "Trying to end the tunnel itself."
	if [ -f "$TUNNEL_PIDFILE" ]; then
		TUNNEL_PID="$(cat $TUNNEL_PIDFILE)"
	 	if ps -p "$TUNNEL_PID" > /dev/null; then
			log "Tunnel is live, trying to exit."
			kill -9 "$TUNNEL_PID"
			sleep 0.5
	 		if ps -p "$TUNNEL_PID" > /dev/null; then
				log "${RED}ERROR:${ENDCOLOR} Tunnel still live after kill command. PID: $tunnel_PID"
				exit 1
			fi

			log "${GREEN}Tunnel closed successfully.${ENDCOLOR}"
			rm "$TUNNEL_PIDFILE"
			exit 0
		else

		log "${YELLOW}WARN:${ENDCOLOR} Tunnel was not open on shutdown."
		exit 0
		fi
	fi
}

start_tunnel () {
	log "Tunnel not running. Spooling up now."
	if [ -f "$TUNNEL_PIDFILE" ]; then
		TUNNEL_PID="$(cat $TUNNEL_PIDFILE)"
		if ps -p "TUNNEL_PID" > /dev/null; then #The tunnel was live at startup
			log "${YELLOW}WARN:${ENDCOLOR} Tunnel wasn't closed on shut down."
			return 1
		fi
	fi
	log "On startup, tunnel is dead, as expected."
	start_time=$SECONDS
	while [ ! -f "$JAVA_PIDFILE" ] || ! ps -p "$(cat $JAVA_PIDFILE)" > /dev/null; do
		sleep 1
		elapsed_time=$(($SECONDS - $start_time))
		if [ "$elapsed_time" -ge 10 ]; then
			log "${RED}ERROR:${ENDCOLOR} Java process didn't start after 10 seconds. Tunnel not starting and exiting early."
			exit 1
		fi
	done
	ssh -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -N -R 0.0.0.0:25565:localhost:25565 "$REMOTE_USER@$PUBLIC_IP" -p 22022 &
	# -o: Option
	# Exit...etc: If the port is unavailable, stop. Don't continue with a dead tunnel
	# Server...etc: Every N seconds, send a keep-alive msg to the other side of the tunnel
	# -N: Don't execute a remote command (just using the tunnel for data)
	# -R: Create a reverse port
	TUNNEL_PID=$!
	echo "$TUNNEL_PID" > "$TUNNEL_PIDFILE"
	log "${GREEN}Tunnel started successfully. tunnel.pid written with $TUNNEL_PID.${ENDCOLOR}"

	"$SCRIPTS_DIR/try_establish_tunnel.sh" &
	TRY_ESTABLISH_PID=$!
	echo "$TRY_ESTABLISH_PID" > "$TRY_ESTABLISH_PIDFILE"
	log "Tunnel restart script launched. PID: $TRY_ESTABLISH_PID"
}

shut_down() {
	log "Stopping server."
	screen -S mc_server -p 3 -X stuff "stop^M"

	# Wait 10 seconds to make sure the server closed correctly
	log "Waiting 10 seconds to confirm Java stopped."
	start_time=$SECONDS
	while ps -p "$JAVA_PID" > /dev/null; do
		sleep 1
		elapsed_time=$((SECONDS - start_time))
		if [ $elapsed_time -ge 10 ]; then
			log "\n${RED}ERROR:${ENDCOLOR} Java process still found after 10 seconds."
			exit 1
		fi
		echo -n "$elapsed_time "
	done
	echo
	rm -f $JAVA_PIDFILE
	log "${GREEN}Server stopped successfully.${ENDCOLOR}"

	#Stop the Screen session
	log "Stopping screen."
	screen -S mc_server -X quit
	sleep 0.1
	screen -ls | grep mc > /dev/null 2>&1 \
	&& log "${YELLOW}WARN:${ENDCOLOR} Screen did not quit." \
	|| log "${GREEN}Screen session quit successfully.${ENDCOLOR}"

	close_tunnel

	rm "$XDG_RUNTIME_DIR"/mc/*.pid >> "$LOGFILE" 2>&1
}

select_server() {
	case "$1" in
   	1)
			log "Starting icebowl"
			sleep 1
			pass="~/mc/icebowl"
			;;
#			2) 
#				log "Starting (server_name)"
#				sleep 1
#				pass="(path/to/server/folder)"
#				;;
		"-m")
			sleep 1
			if [ -n $2 ]; then
				pass="$2"
				log "Launching with path $2"
			else
				pass=""
				log "Path empty!"
			fi
			;;
		"-clear")
			rm "$XDG_RUNTIME_DIR"/mc/*
			log "Clearing PID folder."
			;;
		*)
			log "Current server status:"
			"$SCRIPTS_DIR/is_server_running.sh"
			pass=""
			echo
			log "\nUsage: ./run.sh [-m] [-clear] [0-9].\nUse -m to specify a full path to a server folder.\nUse -c to clear ALL PIDs out of $XDG_RUNTIME_DIR/mc\n"
			cat "$SERVER_DESC_TXT" 2>> "$LOGFILE"
			;;
	esac
}

main () {
	mkdir "$XDG_RUNTIME_DIR/mc" >> "$LOGFILE" 2>&1
	if [ -f "$JAVA_PIDFILE" ]; then
		JAVA_PID=$(cat "$JAVA_PIDFILE")
		log "Java PID file found. PID: $JAVA_PID"
		
		if ps -p "$JAVA_PID" > /dev/null; then #If the PID file is up-to-date	
			log "Server already running."
			if [ "$1" = "q" ]; then #If the first arg is the letter q
				shut_down
			elif [ $# -eq 0 ]; then # Running with no args prints current server status
				echo
				log "Current server status:"
				"$SCRIPTS_DIR/is_server_running.sh"
				log "Server already running. Use screen -r to reconnect."
			fi
		else # PID file is stale
			log "${YELLOW}WARN:${ENDCOLOR} Java PID was stale. Deleting Java PID file. Use this command again."
			rm -f "$JAVA_PIDFILE"
		fi
	else #PID file not found, server is not running
		select_server "$1"
		if [ -z "$pass" ]; then
			log "Not starting server."
		else
			log "Passing: $pass to setup"
			"$SCRIPTS_DIR/setup_mc_screen.sh" $pass & #This helper script calls start.sh, which echoes the pid to the pid file
			screen -S mc_server -D -R
			#Attach here and now. In detail this means: If a session is running, then reattach. 
			#If necessary detach and logout remotely first. 
			#If it was not running create it and notify the user.

			if screen -ls | grep mc_server &> /dev/null; then
				log "${GREEN}Screen started successfully.${ENDCOLOR}"		
			else
				log "${RED}ERROR:${ENDCOLOR} Screen did not start."		
			fi
			start_tunnel
		fi
	fi
}

main "$@"


