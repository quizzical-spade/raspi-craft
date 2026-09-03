# Optional extras
The following is some of the fluff that makes the server easier to run. You're perfectly fine just using `start.sh`, but this will make everything smoother (at the cost of a learning curve). One big issue is that once you've `ssh`'d into your Pi, you can only run one command at a time. So running your `start.sh` script hijacks your terminal, leaving you unable to monitor things like server performance. We're going to use GNU Screen and an advanced startup script to give you your terminal back.

Your file structure should be simple. Create a directory in your home folder titled `mc`. Inside that, create a directory for reach world. Also create a scripts directory. You should have:

```
~/mc/
     scripts/
             example.sh
     sample_world_folder/
             server.jar
             start.sh
             server.properties
                 .
                 .
                 .
              other world files
```

## 1. GNU Screen
### 1a: What is it and why do we want it?
> Screen is a full-screen window manager that multiplexes a physical terminal between several processes, typically interactive shells... There is a scrollback history buffer for each virtual terminal and a copy-and-paste mechanism that allows the user to move text regions between windows.

>When Screen is called, it creates a single window with a shell in it (or the specified command) and then gets out of your way so that you can use the program as you normally would. Then, at any time, you can create new (full-screen) windows with other programs in them (including more shells), kill the current window, view a list of the active windows, turn output logging on and off, copy text between windows, view the scrollback history, switch between windows, etc. All windows run their programs completely independent of each other. Programs continue to run when their window is currently not visible and even when the whole Screen session is detached from the user’s terminal.

- [Screen's manual](https://www.gnu.org/software/screen/manual/screen.html)

Screen is a baby form of containerization software. On a standard Windows computer, you can launch Google Chrome and File Explorer at the same time, viewing and working in both programs. However on the Linux command line, you can only do one thing at a time. Screen gives us some functionality back so we can run the server in the background and still use the Pi.

### 1b: Installing GNU Screen
`sudo apt-get install screen` is the command to run. `sudo` stands for `superuser do`, and is the Linux equivalent to `Run as Administrator`. `apt` is the package manager and `screen` is the name of the package. You'll have to type your password in to give it permission to install.

### 1c: Configuring your GNU Screen
Before we enter Screen, we're going to make things a little more user friendly.

Screen gets its config from `~/.screenrc`. I have provided my screenrc file (`~/extras/.screenrc` in this repo), so just copy it into your system clipboard, create a screenrc with `vim ~/.screenrc`, enter `i`nsert mode and `<Ctrl+Shift+V>` to paste it in. Save with `<:wq>` and you should be good to test.

### 1d: GNU Screen crash course
Once `screen` is installed, things can real Inception-shaped fast, so read this section fully. When in doubt, type `<Ctrl+A><\><y>`, then type `clear<Enter>`. This immediately kills the active Screen session and then clears all text from the terminal.

The reason for these arcane commands (that will be explained momentarily) is that Screen does not *tell* you when it's active. So, you can be in a Screen session without actually knowing it, which can lead to strange, unexplainable behaviour. Using my screenrc adds a little bit of context to Screen. If you launch `screen`, you should be met with this:

<img width="1918" height="1047" alt="screen_quiz_screenrc" src="https://github.com/user-attachments/assets/d95429a3-ab03-48e7-887c-33bdc7ddad23" />

Starting from the bottom:
* The bar reads `1* Alpha   2- Bravo   3 Keep   4 Log`. This shows you the four active windows and their numbers. The blue highlight shows which window is currently active.
* Above is one long white bar. `1 Alpha` shows which window is active on the left region, `4 Log` shows which window is active on the right region.
* The interactable area itself is split into two region, one on the left, one on the right.

Regions are just containers, windows are the actual process. You can focus one region at a time by hitting `<Ctrl+Arrow keys>`. The blue highlight will move to show which window is active. Unfortunately, Screen does not support showing which *region* is active.

Lets say I don't want to have `4 Log` shown in the right region. Navigate to the pane with `<Ctrl+Right Arrow>` and then hit `<F3>` and `<F4>` to cycle between windows. This picks windows based on the bottom bar; hitting `<F4>` repeatedly will cycle through `Alpha`, `Bravo`, `Keep`, and then back to `Log`. A `-` is added next to the number of the *previously displayed* window.

If both region are showing the same window, an `&` is added next to the number and any changes made in one region are reflected in the other.

To explore more easily, try launching `vim` in one window, `top` in another, and `cat` a file in a third so that windows look distinct. You can cycle through my pre-defined layouts with `<Ctrl+F3>` and `<Ctrl+F4>`. Screen launches into `vert_split`, but I also created `big`, `t_pane`, and `tri_split`. You can resize regions by hitting `<F2>` to enter resize mode. Then use `<h>``<j>``<k>``<l>` to resize the active region. Hit `<F2>` to exit resize mode.

When you're done exploring, you'll want to leave. `<Ctrl+A><\><y>` kills Screen, losing all your progress. `<Ctrl+A><d>` merely detaches from Screen, leaving all your windows running in the background. You can reattach with `screen -r`. 

When you start Screen, you can give that session a name with `screen -S (name)`. If you don't, it gets a default name like `pts-0.deb5060-server`. You can see the names of all Screen sessions with `screen -ls`. This gives a lot of information in the format: `(PID).(name) (creation date) (status)`. You can close a Screen session with `screen -S (name) -X quit`.

Summary of keybinds:

| Bind | Action |
|----|----|
| `<Ctrl+A>` | Screen escape character, combine with others for activity |
| `<Ctrl+A><Shift+/>` | Access Screen's help menu. Keybinds presented are defaults, not custom |
| `<Ctrl+A><\><y>` | Kill Screen |
| `<Ctrl+A><d>` | Detach from Screen | 
| `<Ctrl+Arrows>` | Select new active region |
| `<F3>` and `<F4>` | Cycle active window within region |
| `<Ctrl+F3>` and `<Ctrl+F4>` | Cycle active layout |
| `<F2>` | Enter and exit resize mode |
| `<h>` `<j>` `<k>` `<l>` | Resize region while in resize mode |

### 1e: Scripting with Screen
This section represents at least two sleepless nights. I wish the documentation was better, but in lieu of that, enjoy my summary!

Scripting has two parts: making a Screen session and setting it up. Now, there is a command to create a session and detach immediately (allowing other scripts to run setup commands), but I'm not going to tell you what it is, because it's bugged. Using it results in a frozen Screen session, necessitating a system restart or script to get you out of it. So, a different solution.

What we're going to do is put out setup instructions inside a script that only starts executing after a brief delay. During that delay, we're going to manually create a Screen session and *leave it open while the background process runs*. The background process takes over our session, setting everything up before automatically detaching. This is--admittedly--a terrible solution, but it does work!

To run a script in the background, append an `&`, like `./setup_mc_screen.sh &`. 

The code we're running is:
```
#!/bin/bash
setup_mc_screen.sh &
screen -S mc_server -D -R
```
The full contents of `setup_mc_screen.sh` are:
<details>
<summary>In-line comments provided:</summary>
 
```
#!/bin/bash
# ~/mc/scripts/setup_mc_screen.sh
# This script attaches to a premade Screen session, sets the layout, calls start.sh and detaches

SHORT_SLEEP=0.00001
WHICH_SERVER=$1
echo "Server: $WHICH_SERVER"

sleep $SHORT_SLEEP
screen -S mc_server -X layout select tri_split
# -S mc_server: Find a Screen session called mc_server
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
```

</details>

## 2. Automated backups
The next extra is proactive, really. It's saving future you from the sins of past you. After all, keeping backups is just smart system administration. You never know when you're going to change a setting and come back to approximately 300 wandering traders spread across the local area. True story! Luckily, setting it up is fairly simple and then you don't have to worry about it again.

This will require leaving a flashdrive permanently plugged in. 8gb should do if you're saving frequently or running many, many mods. I'm using a 4gb one that lost its shell. Only the best.

### 2a: Auto-mount
The first thing we have to do is tell Linux to trust the flashdrive and automatically mount it. When a flashdrive mounts, it exposes its internal file system to the computer, telling the computer where to "find" the filesystem. If you've ever had Windows ask you "What do you want to do with this USB drive?" it's asking if it should mount it. This has a few steps in order:
<details>
 <summary>1. Find the drive's UUID (Universally Unique IDentifier)</summary>
 
 Plug your drive in and use the command `lsblk` (list block--a lot of commands refer to storage as "blocks"). This should return something like:
 
 ```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda           8:0    1   3.7G  0 disk
└─sda1        8:1    1   3.7G  0 part
nvme0n1     259:0    0 238.5G  0 disk
├─nvme0n1p1 259:1    0   976M  0 part /boot/efi
├─nvme0n1p2 259:2    0 225.2G  0 part /
└─nvme0n1p3 259:3    0  12.3G  0 part [SWAP]
```
Here the `nvme` is my operating system. I know that because I know that my OS is running off an M.2 NVME drive. If you don't know that, look for the size. My USB drive is a USB A device that can hold ~4gb, so it's reasonable to assume that it's `sda1`. Write down or remember the name. Note: the device is `sda` but the partition is `sda1`. Subtle difference, but it does matter. Like a hardcover book: `sda` is the covers, the legal pages, the dedication, etc. `sda1` is the actual story.

Next, we'll get your device's PARTUUID (Partition UUID) with `sudo blkid` (block ID). If you fail to prepend `sudo`, you'll get a `command not found` error. Your output should look something like this:

 ```
/dev/nvme0n1p3: UUID="aa1e28d3-5b7b-40b4-92fb-f41db6fc06a8" TYPE="swap" PARTUUID="2a02b7ab-c69d-4794-b054-79f40e479d9f"
/dev/nvme0n1p1: UUID="6251-96A4" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="ecb2303c-f768-460f-bc15-f1a2fefd4ea0"
/dev/nvme0n1p2: UUID="18bafc0e-0542-4faa-bdf2-805cc46dc565" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="c271382c-bfc5-48d7-9c36-784ef9176b6d"
/dev/sda1: LABEL="BARE_MET_4" UUID="FE9B-FFD7" BLOCK_SIZE="512" TYPE="exfat" PARTUUID="00659afc-01"
```
Here's more confirmation that `sda1` is the right device: it's labelled as "BARE_MET_4". This is what you'd see in the file explorer if you plugged the drive into a Windows machine. We'll need the PARTUUID, so write that down. Also note the type. 
<details>
 <summary>If yours is not "ext4":</summary>
 
 We are going to change the formatting of your USB drive. Don't panic, it's less scary than it sounds. We want it to speak to Linux natively. Other common formats (like NTFS) sometimes don't play nice. We're just going to install a tool and re-format the `sda1` partition.

 ```
sudo apt-get install mkfs.ext4
sudo umount /dev/sda1
sudo mkfs.ext4 -L "DAVE" /dev/sda1
```
That's it! First line installs a package. Second line makes sure that the drive isn't mounted. Third line reformats the drive as ext4 and names it DAVE.

Run `sudo blkid` again and see:
```
/dev/nvme0n1p3: UUID="aa1e28d3-5b7b-40b4-92fb-f41db6fc06a8" TYPE="swap" PARTUUID="2a02b7ab-c69d-4794-b054-79f40e479d9f"
/dev/nvme0n1p1: UUID="6251-96A4" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="ecb2303c-f768-460f-bc15-f1a2fefd4ea0"
/dev/nvme0n1p2: UUID="18bafc0e-0542-4faa-bdf2-805cc46dc565" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="c271382c-bfc5-48d7-9c36-784ef9176b6d"
/dev/sda1: LABEL="DAVE" UUID="FAFF-B1DC" BLOCK_SIZE="512" TYPE="ext4" PARTUUID="00659afc-01"
```
Dave and his PARTUUID!
</details>
</details>

<details>
 <summary>2. Give the drive a mountpoint within the computer's filesystem</summary>

 USB drives are typically mounted to `/media` if they're controlled by the OS and to `/mnt` if they're controlled by a system administrator (in this case, us!). All we have to do is make a directory that we'll later point the drive to.

 `sudo mkdir /mnt/mc_backup` should do nicely. Lastly, we put it under our command. By default, it's owned by `root`, so let's change ownership: `sudo chown (username):(username) /mnt/mc_backup`.

</details>

<details>
 <summary>3. Pair the two into /etc/fstab/ to tell the computer to automount that specific drive in that specific place</summary>

 Now we edit the system's `fstab` (file system table). This tells the system "When you see this drive, put it here:". We're going to glue a line to the bottom for our USB drive. That line is:
 
 ```
PARTUUID=00659afc-01(YOUR_PART_UUID) /mnt/mc_backup ext4 defaults,nofail,x-systemd.automount,uid=(YOUR_UID),gid=(YOUR_GID),fmask=0022,dmask=0022 0 2
```

What does that all mean?
`PARTUUID` the unique ID of the USB drive's partition
`/mnt/mc_backup` where to drop the drive's contents
`ext4` tell the OS that we know the drive is formatted as ext4
`defaults` use whatever standard mount options the OS likes
`nofail` if this mounting fails, don't stop the OS from booting up 
`x-systemd.automount` whenever something access the mountpoint (`/mnt/mc_backup`) try and mount the device

`0` don't `dump` the filesystem (an older backup system)
`2` run `fsck` automatically (a Linux filesystem check and repair utility), but only after checking other devices

You edit the `fstab` with `sudo vim /etc/fstab`. Get that line in, save, quit, and we can test it.

To test, we're going to reload `systemctl`. As the name implies, this is a utility that controls a lot of processes. We reload it so it reads the new `fstab`. We then manually call `mount` on the mount point to see if the automount works. Finally, we check to see if the drive mounted correctly.

```
sudo systemctl daemon-reload
sudo mount /mnt/mc_backup
findmnt /mnt/mc_backup
```

My output looks like:

```
TARGET         SOURCE    FSTYPE OPTIONS
/mnt/mc_backup /dev/sda1 exfat  rw,relatime,fmask=0022,dmask=0022,iocharset=utf8,errors=remount-ro
```
The TARGET and SOURCE look right, so that's that dusted. Those options are the default mount options mentioned earlier.
</details>

### 2b: rsnapshot
You could many copy the entire server folder into our new `mc_backup` directory, but that sucks for two reasons. The less obvious reason is that over time, you're creating copies of files that don't change. Duplicating this data sucks, especially if your `Dave` is only 4gb! `rsnapshot` is a form of delta tracking--it only saves changes that are made. This greatly cuts down on storage space required. Install it with `sudo apt-get install rsnapshot`.

I'll be honest, `rsnapshot` kinda does my head in. What we're going to do is very simple. We're going to save 8 `alpha` snapshots across two days and 7 `beta` snapshots a week. So if something breaks on Monday at 1p, we can roll back to:
* Monday at noon
* Monday at 6a
* Monday at midnight
* Sunday at 6p
* Sunday at noon
* Sunday at 6a
* Sunday at midnight
* Saturday at 6p
* Sunday, Sat., Fri., Thur., Wed., Tue., last Mon., all at noon of those days

Confused yet? Let me explain. `rsnapshot` is not actually a backup *scheduler*, it's a backup *rotator*. All we're going to tell `rsnap` is, "Hold onto these 8 `alpha` snaps. When you get handed a new one, throw the oldest one out." We then use `cron` to control how quickly we hand `rsnap` those snaps. We also say, "Keep track of these `beta` snaps, too. When I tell you, take the oldest `alpha` and rename it as the newest `beta`. You're keeping 7 of those betas."

`rsnap` is controlled by a config file that lives in `/etc/rsnapshot.conf`. Unfortunately, it's ~260 lines long and most of them don't matter. 

> [!NOTE]
> All elements are separated by tab characters, not spaces. rsnapshot will crash otherwise.
> 
<details>
 <summary>Let's break down the lines we need to change:</summary>
 

 
 Start editing with `sudo vim /etc/rsnapshot.conf`. We'll go section by section.

 ```
###########################
# SNAPSHOT ROOT DIRECTORY #
###########################

# All snapshots will be stored under this root directory.
#
snapshot_root   /mnt/mc_backup

```
Self-explanatory, this is where `rsnap` will dump each snap.


&nbsp;

```
#################################
# EXTERNAL PROGRAM DEPENDENCIES #
#################################

# LINUX USERS:   Be sure to uncomment "cmd_cp". This gives you extra features.
# EVERYONE ELSE: Leave "cmd_cp" commented out for compatibility.
#
# See the README file or the man page for more details.
#
cmd_cp         /bin/cp

# uncomment this to use the rm program instead of the built-in perl routine.
#
cmd_rm          /bin/rm

# rsync must be enabled for anything to work. This is the only command that
# must be enabled.
#
cmd_rsync       /usr/bin/rsync

.
.
.

# Comment this out to disable syslog support.
#
cmd_logger      /usr/bin/logger
```
These were the defaults for me. Everything else should be commented out.

&nbsp;

```
#########################################
#     BACKUP LEVELS / INTERVALS         #
# Must be unique and in ascending order #
# e.g. alpha, beta, gamma, etc.         #
#########################################

retain  alpha     8
retain  beta      7
#retain gamma   4
#retain delta   3
```
This is the business. We're telling `rsnap` how many shots to keep before rotating the oldest one out. 


&nbsp;

```
############################################
#              GLOBAL OPTIONS              #
# All are optional, with sensible defaults #
############################################

# Verbose level, 1 through 5.
# 5     Debug mode      Everything
#
verbose         5

# Same as "verbose" above, but controls the amount of data sent to the
# logfile, if one is being used. The default is 3.
#
loglevel        3

# If you enable this, data will be written to the file you specify. The
# amount of data written is controlled by the "loglevel" parameter.
#
logfile /mnt/mc_backup/rsnapshot.log

# If enabled, rsnapshot will write a lockfile to prevent two instances
# from running simultaneously (and messing up the snapshot_root).
# If you enable this, make sure the lockfile directory is not world
# writable. Otherwise anyone can prevent the program from running.
#
lockfile        /mnt/mc_backup/rsnapshot.pid
```
I have a healthy distrust of backup utilities, so I have logging quite high and I keep the logs on the external device. Logs don't help me if the system dies, taking the logs down with it. Everything else in this section is commented out.

&nbsp;

```
###############################
### BACKUP POINTS / SCRIPTS ###
###############################

# LOCALHOST
backup  /home/quiz/mc           minecraft/
```
And finally, we tell it what we want to backup and the name of the directory that we'll put it in (making our final path `/mnt/mc_backup/minecraft`).

I've included my `/etc/rsnapshot.conf` in the `extras` folder of this repo.
</details>
Let's test it! Start by running `rsnapshot configtest`. If there are permission issues, you'll get something like:

```
----------------------------------------------------------------------------
rsnapshot encountered an error! The program was invoked with these options:
/usr/bin/rsnapshot configtest
----------------------------------------------------------------------------
ERROR: /etc/rsnapshot.conf on line 23:
ERROR: snapshot_root /mnt/mc_backup - snapshot_root exists but is not \
         writable
ERROR: /etc/rsnapshot.conf on line 239:
ERROR: backup /home/quiz/mc minecraft/ - snapshot_root needs to be defined \
         before backup points
ERROR: ---------------------------------------------------------------------
ERROR: Errors were found in /etc/rsnapshot.conf,
ERROR: rsnapshot can not continue. If you think an entry looks right, make
ERROR: sure you don't have spaces where only tabs should be.
```
Check your `fstab` and make sure there aren't spaces where tabs should be in the `.conf` file.

Next, run `rsnapshot -t alpha`. `-t` is going to run as a test; it won't actually do anything, but it'll print output explaining what it would have done:

```
WARNING: The verbosity-level is "3" despite subsequent declaration at line 110.
echo 136654 > /mnt/mc_backup/rsnapshot.pid
mkdir -m 0755 -p /mnt/mc_backup/alpha.0/
/usr/bin/rsync -a --delete --numeric-ids --relative --delete-excluded \
    /home/quiz/mc/ /mnt/mc_backup/alpha.0/minecraft/
touch /mnt/mc_backup/alpha.0/
```
It seems like it should work! it makes a directory (`/mnt/mc_backup/alpha.0/`), uses `rsync` to move the files from `/home/quiz/mc/` to `/mnt/mc_backup/alpha.0/minecraft/` and then verifies that the destination exists with `touch /mnt/mc_backup/alpha.0/`.

Make sure the server is off and run it for real: `rsnapshot alpha`. Then you can go investigate with `ls`. Your final backup path should be something like `/mnt/mc_backup/alpha.0/mc/home/(username)/mc/`.

To rollback, just `cp` the files you need off the USB drive and back into the `/home/` path. I'd recommend saving your local `mc` folder, even if it's messed up. Just run `cp -r mc mc_bugged`, so you don't worry about your rollback wiping things permanently.

### 2c: Scripting
Now, if saving were this easy, everyone would do it! There's another wrinkles. Minecraft itself is constantly saving; it writes to files to track player position, world state, etc. Making a backup while it's doing that would be bad, as we could catch it mid-save, snapshotting data that was in-progress. To avoid this, we have a simple script. All it does it stops the server from saving, makes a backup, and then re-enables saving.

Okay, first stop is actually a detour:
<details>
 <summary>config.sh:</summary>

 ```
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
```

Nothing crazy, we just store common paths in a config file so that we can source this file once rather than maintain a list of paths in every script. The colour codes will be used to add colours to our logfiles later.

</details>

<details>
<summary>The file execute_mc_backup.sh:</summary>
 
```
#!/bin/bash
# ~/mc/scripts/execute_mc_backup.sh

source "$HOME/mc/scripts/config.sh"

echo >> "$LOGFILE" 2>&1
echo "$(date) - $1" >> "$LOGFILE" 2>&1

if [ -f "$JAVA_PIDFILE" ]; then
        JAVA_PID="$(cat $JAVA_PIDFILE)"
        if ps -p $JAVA_PID > /dev/null; then
                echo "Disabling saving" >> "$LOGFILE" 2>&1
                screen -S mc_server -p 3 -X stuff "save-off^M"

                trap 'echo "$(date): Enabling saving" >> "$LOGFILE" 2>&1; screen -S mc_server -p 3 -X stuff "save-on^M"' EXIT

                rsnapshot "$1" >> "$LOGFILE" 2>&1
                exit_code=$?
                echo "Rsnap exited with code: $exit_code" >> "$LOGFILE" 2>&1
        else
                echo "PID file found, but no Java process with matching PID, not running backup" >> "$LOGFILE" 2>&1
        fi
else
        echo "PID file not found, not running backup" >> "$LOGFILE" 2>&1
fi

```

</details>



<details>
<summary>Let's look at it in chunks.</summary>
 
```
#!/bin/bash
# ~/mc/scripts/execute_mc_backup.sh

#----------- USER VARIABLE ---------------#
LOGFILE="/mnt/mc_backup/backup_script.log"
JAVA_PIDFILE="/run/user/1000/mc/java.pid"

echo >> "$LOGFILE" 2>&1
echo "$(date) - $1" >> "$LOGFILE" 2>&1
```
Boilerplate. Only interesting this is the `$1` in the last line. The script is called with `alpha` or `beta` as an argument, so any instance of `$1` is one of those two keywords. We want that logged so that we can isolate what fails.

&nbsp;

```
if [ -f "$JAVA_PIDFILE" ]; then
        JAVA_PID="$(cat $JAVA_PIDFILE)"
        if ps -p $JAVA_PID > /dev/null; then
```
This is a standard check. It checks: if the PID file exists, what the PID file contains, and if the PID inside a live PID or if it is stale (meaning referring to a dead process).

&nbsp;

```
                echo "Disabling saving" >> "$LOGFILE" 2>&1
                screen -S mc_server -p 3 -X stuff "save-off^M"

                trap 'echo "$(date): Enabling saving" >> "$LOGFILE" 2>&1; screen -S mc_server -p 3 -X stuff "save-on^M"' EXIT
```
If the Java process is running, the server must be running, so we tell it to stop saving using `stuff`. The `trap` line ensures that no matter how the script exists, saving is re-enabled and the exit is logged. The `;` separates complete Bash statements, so the `echo` and the `screen` command are separate.

&nbsp;

```
                rsnapshot "$1" >> "$LOGFILE" 2>&1
                exit_code=$?
                echo "Rsnap exited with code: $exit_code" >> "$LOGFILE" 2>&1
        else
                echo "PID file found, but no Java process with matching PID, not running backup" >> "$LOGFILE" 2>&1
        fi
else
        echo "PID file not found, not running backup" >> "$LOGFILE" 2>&1
fi
```
Here at the end some very simple checks and logging, nothing special.

</details>

### 2d: Cron
`cron` is a task scheduler. We're going to use it to schedule our script to run in the background. Earlier, I said:

> We're going to save 8 `alpha` snapshots across two days and 7 `beta` snapshots a week.

That works out to one `alpha` every 6 hours and one `beta` every 24. The `betas` are going to go off at 3p each day, so let's understand `cron` to the point of doing that. 

#### 2d: Structure of crontab
The `crontab` (cron table) is structured suchly (taken from `/etc/crontab`):

```
# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  *  command to be executed
```
So let's say we were scripting a traditional clock. We want it to chime at the top of the hour, every hour--1:00, 2:00, 3:00, etc. This is the "zeroth" minute of every hour. The word "every" on the command-line is represented by a `*`, so we'd read this sample line:
```
0 * * * * bong.sh
```
as "On the zeroth minute of every hour of every day of every month of every week day, run bong.sh"

How about something more complicated?
```
0 5,17 * * * toggle_sun.sh
```
This pretends that we live in a world where the sun rises and sets at exactly 5am (5) and 5pm (17). We toggle the sun, "On the zeroth minute of hours 5 and 17 of every day...etc.)

And finally, something useless:

```
7 14 28 11 2 world_domination.sh 
```
"At 14:07 on the (28th of November or any Tuesday), world domination."

#### beta snapshots
```
50 14 0 0 0 ~/mc/scripts/execute_backup.sh beta
```
I want the backup to be all set by 3p, so I'll set it to go off at 2:50p.

#### alpha snapshots
We want to save a snap every 6 hours (48 hours divided by 8 shots). We could list them all out, like `0,6,12,18`, but there's a smoother way.
```
0 */6 * * * ~/mc/scripts/execute_backup.sh alpha
```
"On the zeroth minute of any hour divisible by 6, of every day...etc. execute an alpha backup". This gives us midnight (00:00), 6a (06:00), noon (12:00), and 6p (18:00).

#### Editing crontab
Editing cron is as easy as `crontab -e`. Pick your favourite text editor (vim.basic is better than vim.tiny), and it's off to the races. Make your crontab look like this:

```
# 
# A bunch of commented lines
#
50 14 0 0 0 ~/mc/scripts/execute_backup.sh beta
0 */6 * * * ~/mc/scripts/execute_backup.sh alpha
```

## 3. Advanced startup script
`start.sh` is cool and all, but we can do better! We can make our script work for us. We can make it check the status of the server, let us select which sever we want to start, and make sure that the server actually shuts down when we quit. This glorious piece of scripting will be called `run_mc.sh`. No points for creativity. The following sections each correspond to one function within the file, so if you want to look at the full thing, check the extras folder in the repo.
### Boilerplate + logging
```
#!/bin/bash
# ~/run_mc.sh

source "$HOME/mc/scripts/config.sh"

touch "$LOGFILE"
echo >> "$LOGFILE"

log() {
    printf '%b\n' "$*" | tee -a "$LOGFILE"
}
```
The first function `log` is as simple as it says on the tin. It takes whatever argument `"$*"` and passes it through `printf` (print formatted), telling it to treat `b`ackslashed escape characters as escape sequences (which gives us our colours). It then calls `tee` to copy the output and append it into the logfile.

### 3a: Main + logging
```
main () {
        if [ -f "$JAVA_PIDFILE" ]; then
                JAVA_PID=$(cat "$JAVA_PIDFILE")
                log "Java PID file found. PID: $JAVA_PID"
                if ps -p "$JAVA_PID" > /dev/null; then #If the PID file is up-to-date
                        log "Server already running."

```
This is a standard check. It checks: if the PID file exists, what the PID file contains, and if the PID inside a live PID or if it is stale (meaning referring to a dead process).

&nbsp;

```
                        if [ "$1" = "q" ]; then #If the first arg is the letter q
                                shut_down
                        elif [ $# -eq 0 ]; then # Running with no args prints current server status
                                echo
                                log "Current server status:"
                                "$SCRIPTS_DIR/is_server_running.sh"
                                log "Server already running. Use screen -r to reconnect."
                        fi
```
Here `shut_down` is a function call that doesn't take an argument. More on that later, but for now trust that it does what you think.

&nbsp;

```
                else # PID file is stale
                        log "${YELLOW}WARN:${ENDCOLOR} Java PID was stale. Deleting Java PID file. Use this command again."
                        rm -f "$JAVA_PIDFILE"
                fi
```
This continues our standard check from earlier. If the PID file is stale, it means that the Java process ended but the `java.pid` file was never deleted. We do that deletion and instruct the user to run again.

First instance of colours! If you forget the `${ENDCOLOR}`, everything else your terminal prints will be yellow.

&nbsp;

```
        else #PID file not found, server is not running
                select_server "$1"
                if [ -z "$pass" ]; then
                        log "Not starting server."
                else
                        log "Passing: $pass to setup"
                        "$SCRIPTS_DIR/setup_mc_screen.sh" $pass & #This helper script sends the start server command and echoes the pid to the pid file
                        screen -S mc_server -D -R
                        #Attach here and now. In detail this means: If a session is running, then reattach.
                        #If necessary detach and logout remotely first.
                        #If it was not running create it and notify the user.
```
`select_server "$1"` is another function call. The user can select which server to launch using a number (or manually passing a path). `$pass` is a variable set by `select_server`. If nothing is `$pass`ed, we don't want to start the server.

`setup_mc_screen.sh` was explained earlier in this doc!

&nbsp;

```
                        if screen -ls | grep mc_server &> /dev/null; then
                                log "${GREEN}Screen started successfully.${ENDCOLOR}"
                        else
                                log "${RED}ERROR:${ENDCOLOR} Screen did not start."
                        fi
                fi
        fi
}
```
The last of the sanity checks and the end of main. If `screen` didn't launch a Session, we have huge problems as the Java process lives inside of it. That's why we reserve `RED` for script-breaking issues, while `YELLOW` is just for things that aren't quite right.

### 3b: Server status
Same deal, but this time we'll examine `is_server_running.sh`. This is a much simpler script that does the same thing in a few ways!
```
#!/bin/bash
# ~/mc/scripts/is_server_running.sh
# Called by run_mc_command.sh when no args are passed

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
```
We've seen this before, just another standard check. This time there's a `JAVA_PID_VALID` flag to help the next chunk.

&nbsp;

```
java_status=$(ps aux | grep -v grep | grep "$JAVA_PID")
echo -n "Java: "
if [[ "$JAVA_PID_VALID" == "true" ]]; then
        echo "$java_status"
else
        echo "Dead."
fi
echo
```
We now look up the Java process using it's PID. If the PID was valid, we print the output of the lookup. If it's not, we just report "Dead". Note the `[[` and `""` around text. Bash enforces types in ways foreign to most programming languages.

`ps aux` stands for `p`rocess `s`tatus for `a`ll users, in a `u`ser readable format, e`x`cluding those controlled by a terminal.

`grep -v grep` calls `grep` with flag in`v`ert to filter out lines containing `grep`. If we don't do this, we get two lines back: one containing info about the Java process and the other containing "grep (PID)", which isn't useful.


&nbsp;

```
screen_status=$(screen -ls | grep mc)
screen_exit=$?
echo -n "Screen: "
if [ $screen_exit -eq 0 ]; then
        echo "$screen_status"
else
        echo "Dead."
fi
echo
```
This is more of the same, but this time `grep`ing on `screen -ls`, which lists all active `screen` sessions. `screen` returns zero when it finds something, so we check for that and then print the session details.


&nbsp;

```
echo "PID dir:" 
pids=""
for file in "$XDG_RUNTIME_DIR"/mc/*; do
	if [ -f "$file" ]; then
		echo "$file: $(cat $file)"
	fi
done
echo
```
And finally, we print all the PID files and their contents. Currently this is only used for the Java process, but it is extensible.

### 3c: Server selection
This section covers a single case statement that I threw into a function to make `main()` more readable.
```
select_server() {
        case "$1" in
        1)
                        log "Starting icebowl"
                        sleep 1
                        pass="~/mc/icebowl"
                        ;;
```
The `sleep` is just so that the user can read that they selected the right server. The `pass` variable came up in `main()`, too. It gets passed to `setup_mc_screen.sh` to `cd` into the correct directory and start the right server. The `;;` just mark the end of the case.

```
#                       2)
#                               log "Starting (server_name)"
#                               sleep 1
#                               pass="(path/to/server/folder)"
#                               ;;
```
Uncomment these lines and replace everything in `()` for your own server!


&nbsp;


```
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
```
`m`anual mode allows the user to select a server by specifying the path to the directory. It validates the user's input to make sure that it actually exists, but it does nothing to check that the path is valid. I only ever use it for testing, it's usually literally faster to add a case statement.

`clear` will delete all PID files in the PID folder. Use it carefully as it doesn't do any checks to make sure that the processes are actually dead.

&nbsp;

```
                *)
                        log "Current server status:"
			            "$SCRIPTS_DIR/is_server_running.sh"
			            pass=""
			            echo
			            log "\nUsage: ./run.sh [-m] [-clear] [0-9].\nUse -m to specify a full path to a server folder.\nUse -c to clear ALL PIDs out of $XDG_RUNTIME_DIR/mc\n"
			            cat "$SERVER_DESC_TXT" 2>> "$LOGFILE"
                        ;;
        esac
```
In the `cron` section I explained that the `*` signifies "everything" in Linux. As the final statement, it means "anything that didn't apply above". The block accomplishes two goals. Firstly, it shows the user the status of the server just by running `./run_mc_command.sh`. Secondly, if you ever forget which server is which, it prints usage instructions and shows you the textfile that you wrote that explains which server is which.

### 3d: Graceful shutdown
I do not claim that this is the best way to accomplish this goal, but it does work. Be forewarned.

```
shut_down() {
        log "Stopping server."
        screen -S mc_server -p 3 -X stuff "stop^M"
```
Simple enough, tell the server to stop through `screen`. Note that we can't just kill the Java process, because that interrupts the server and prevents it from saving.

&nbsp;

```
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
```
This...this is not pretty. It checks every second to make sure that the Java process stopped. Once the process is confirmed as stopped, it deletes the PID file. If the process doesn't stop, it throws an error. `-ge` is `g`reater than or `e`qual to, so it only checks for 10 seconds. Every second, it prints another number to the terminal.

&nbsp;

```
        #Stop the Screen session
        log "Stopping screen."
        screen -S mc_server -X quit
        sleep 0.1
        screen -ls | grep mc > /dev/null 2>&1 \
        && log "${YELLOW}WARN:${ENDCOLOR} Screen did not quit." \
        || log "${GREEN}Screen session quit successfully.${ENDCOLOR}"

       	rm "$XDG_RUNTIME_DIR"/mc/*.pid >> "$LOGFILE" 2>&1
}
```
The `&&` and `||` are fancy symbols meaning "run the next command if the preceding one returned 0 (for &&) or 1 (for ||)". `screen -ls` exits `0` if it finds something. So the `YELLOW` log only gets run if `screen` finds something. If it does find something, it returns 1 and the `GREEN` log runs.

The `rm` line just clears out all the PID files we've been using to track processes.

## 4. SSH Tunnel
This is a very niche application, if your port forwarding doesn't work, troubleshoot in other ways first. Adding this functionality edits almost every file, find the updated versions in this repo under `/extras/ssh/*`.

You're going to need access to another computer that lives inside an additional network.
### What is it and why do I want it?
This is a way to expose the IP of a remote machine on a *different* network's and send the traffic from that remote address to your local machine. You only want to do this if you are unable or unwilling to port forward. In my case, I live in an apartment building that uses the same ISP for every unit. As a result, that ISP has us behind a CGNAT, so my entire building shares an IP address and no tenant can port forward.

### What are the risks?
Setting up a reverse tunnel is not exactly as dangerous as regular port forwarding. The difference is you're now exposing the remote network to the public traffic rather than your own. Additionally, you're sending traffic from a trusted connection (the remote machine) to your local machine. So if your remote network/machine is insecure, you're basically opening your local network up to the entire internet.

In my case, my remote network is managed by a network engineer, so I'm not concerned. Your mileage may vary, don't compromise your network for a Minecraft server.
### How do I do it?
<details>
 <summary>On the remote:</summary>
 
 1. You'll need a machine that has an SSH server installed.
     1. In its `sshd_config`, set `GatewayPorts` to `yes`. 
 2. Set up a router/firewall rule to port forward ports `22022`* and `25565` to that machine. 
     1. Set the remote machine to have a static IP as necessary. 

 *Note: this is *not* the standard port for SSH, (that's `22`). We're doing this on purpose to make it slightly more difficult for scrapers. You should probably do the same for the remote-side Minecraft port, but that would involve telling people to connect to a port like `25665`, which may require explaining what a port is to your friends. This guide will use `22022` for SSH and the standard `25565` Minecraft port.
</details>

<details>
 <summary>On the local:</summary>
 Run the command `ssh -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -N -R 0.0.0.0:25565:localhost:25565 (REMOTE_USER)@(REMOTE_IP) -p 22022`. That's literally it, so let's understand what this is all doing.
 
* `-o ExitOnForwardFailure=yes` is telling SSH to exit the process if the endpoint can't be reached. In our case, this means that if another process is using the remote port (like another Minecraft server), the tunnel will exit with a failure code.
* `-o ServerAliveInterval=60` tells SSH to send a keep-alive "heart beat" packet every 60 seconds. This prevents the tunnel from being closed due to inactivity (in theory, more on this later).
* `-N` tells SSH that we'll only be using this for port forwarding, we won't be sending commands or requiring a shell. This saves system resources.
* `-R 0.0.0.0:25565:localhost:25565` is the meat of it. `-R` is for a reverse tunnel. `0.0.0.0:25565` tells the remote to bind traffic on all of its interfaces that is bound for port `25565` and send it to `localhost:25565` on the local machine.
 
</details>

A picture is worth a thousand words, unless I drew it. Then it's about 500.

<img width="1224" height="1041" alt="ssh_reverse_tunnel" src="https://github.com/user-attachments/assets/b57379c4-f1a8-4b85-a4da-8f2860a4a1cf" />


### How do I script it?
The theme of this section is: "Well shit, if it's stupid but it works..." so don't take anything here to be good style, good form, or a good idea.

I added the following functions into the startup script: `start_tunnel` and `close_tunnel` as well as a call to two new files, `~/mc/scripts/try_establish_tunnel.sh` and `~/mc/scripts/secrets_config.sh`. The full files is added in this repo in `/extras/ssh/*`.

<details>
 <summary>secrets_config.sh:</summary>
 
 ```
#!/bin/bash
# Secrets file

#-------- SECRETS ----------#
REMOTE_USER="(YOUR_REMOTE_USER)"
PUBLIC_IP="(YOUR.REMOTE.IP.ADDRESS)"
```
</details>

<details>
<summary>start_tunnel:</summary>
 
 ```
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
 ```
The only thing interesting to note is that this function has to wait for the Java process to get going. The SSH command expects the port to be in use. If it isn't, it throws an error.

</details>

<details>
<summary>~/mc/scripts/try_establish_tunnel.sh:</summary>

 ```
#!/bin/bash
#try_establish_tunnel.sh
# Called by run_mc_command.sh

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
```
Every 15 seconds, check if the tunnel is running. If it isn't, get it going! This is, admittedly, a very dumb solution. I think you're supposed to set this up with `nohup`, or maybe as a `systemd` daemon? But that's above my pay grade and--critically--this works!
</details>

<details>
<summary>close_tunnel:</summary>

 ```
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
                        # kill $(ps aux | grep -E "try_establish_tunnel.sh [0-9]" | grep -v grep | awk '{print $2}') 2>/dev/null
                        # Kill the infinite loop by searching for open files, REGEXing for run_mc.sh and some numbers,
                        # pipe the result through grep -v which selects every line that doesn't contain grep
                        # (removing the original grep -E process),
                        # then print the second column without printing any errors.
                fi
        else
                log "${YELLOW}WARN: try_establish loop was not running.${ENDCOLOR}"
        fi
```
Just a mid-function note: that commented block is an ugly way to double check that the infinite restart loop isn't running. 

&nbsp;


```
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
```
The usage of `kill -9` is not encouraged. It means "kill it with fire immediately and with extreme prejudice. There are better ways, I'm sure.

</details>

# Congratulations
You now have a very robust and easy to use Minecraft server with some hidden functionality to make using it a breeze. I hope you feel educated on a few more Linux systems and that you can see how you can utilize scripting and free utilities to make your life easier!
