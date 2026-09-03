#!/bin/bash
# ~/mc/(server_folder)/start.sh

sh -c 'echo $$ > "$XDG_RUNTIME_DIR/mc/java.pid"; exec java -Xmx8G -Xms8G -jar server.jar nogui'

