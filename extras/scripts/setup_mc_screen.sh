#!/bin/bash
# ~/mc/scripts/setup_mc_screen.sh
# This script attaches to a premade Screen session, sets the layout, calls start.sh and detaches
SHORT_SLEEP=0.00001
WHICH_SERVER=$1
echo "Server: $WHICH_SERVER"

sleep $SHORT_SLEEP 
screen -S mc_server -X layout select tri_split
# -S mc_server: Start or find a Screen session called mc_server
# -X: Send it a command
# layout select tri_split: Select the pre-defined layout named tri_split
sleep $SHORT_SLEEP
screen -S mc_server -p 3 -X stuff "cd $WHICH_SERVER^M./start.sh^M"
# -p 3: Target window 3
# -X: Send it a command
# stuff: Tells Screen to enter keystrokes
# "cd $WHICH_SERVER": Change directory given the path the user selected
# "^M": Screen's code for the ENTER key
sleep $SHORT_SLEEP
screen -S mc_server -p 1 -X stuff "cd $WHICH_SERVER^M"
sleep $SHORT_SLEEP
screen -S mc_server -p 4 -X stuff 'top^M'
sleep 0.027 
screen -S mc_server -p 4 -X stuff '1^M'
# This and the command above start top in window 4
# wait for it to get going, then hit the 1 key
# so the user can see each CPU core
sleep $SHORT_SLEEP
screen -S mc_server -d
# -d: Detach from the session
