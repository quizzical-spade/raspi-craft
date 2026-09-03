#!/bin/bash
# ~/mc/scripts/try_establish_tunnel.sh
# Called by run_mc_command.sh, but only used for SSH reverse tunnels

source "$HOME/mc/scripts/config.sh"
source "$HOME/mc/scripts/secrets_config.sh"

#While Java is running on purpose
while [ -f "$JAVA_PIDFILE" ] && ps -p "$(cat $JAVA_PIDFILE)" > /dev/null; do
	#If the tunnel PIDFILE doesn't exist or the tunnel process is dead
	if [ ! -f "$TUNNEL_PIDFILE" ] || ! ps -p "$(cat $TUNNEL_PIDFILE)" > /dev/null; then
		echo "${YELLOW}WARN:${ENDCOLOR} Tunnel died after startup. Time of down: $(date). This message spawned by $(cat TRY_ESTABLISH_PIDFILE)." > "$LOGFILE"
		ssh -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -N -R 0.0.0.0:25565:localhost:25565 "$REMOTE_USER@$PUBLIC_IP" -p 22022 &
		TUNNEL_PID=$!
		echo "$TUNNEL_PID" > "$TUNNEL_PIDFILE"
	fi
	sleep 15;
done
echo "${YELLOW}WARN:${ENDCOLOR} Loop exiting at $(date)." > "$LOGFILE"
rm "$TRY_ESTABLISH_PIDFILE"
