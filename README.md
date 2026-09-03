# raspi-craft
A guide and starting files for running a Minecraft server on a Raspberry Pi 5 using [Purpur](https://purpurmc.org/docs/purpur/), [`GNU Screen`](https://www.gnu.org/software/screen/)* and some scripts. At the end of this guide, you should have a Raspberry Pi that will launch a GNU Screen session on reboot. That Screen session will display the server output, current RAM/CPU usage and a blank terminal. You will then be able to remotely access the Screen session using SSH from any other computer on the network. 

Throughout this guide, all command line commands and filenames will be formatted like `this`. All keystrokes will be formatted like `<this>`. Anything optional will surrounded in [ ], like `[so]`. Placeholder values that should be replaced will be encapsulated like `(this)`.

\* Technically it's just called Screen, but trying to Google for that is one of Dante's Circles.

## Table of Contents
There's a premade Github version in the top right of this panel! Look for this button:

<img width="939" height="500" alt="The table of contents button" src="https://github.com/user-attachments/assets/dff2d678-4878-4145-a3e3-09b736f70d32" />

## Required materials
* Raspberry Pi 5* (other models may work, but RAM may be a limiting factor). I purchased the [Complete Kit from Vilros for $150](https://vilros.com/products/raspberry-pi-5?variant=40082990399582).
  * Additional hardware for the Pi including:
    * Power supply
    * Case with active cooling
    * Mouse + keyboard with USB A
    * microSD for the Pi's storage
      * A method to program the SD
    * Micro HDMI to [HDMI/DVI/other] cable
    * Ethernet cable (highly recommended)
* Some basic knowledge of: (recommended, but this is a good way to learn!)
  * Linux command line
  * Vim
* A main computer for remotely accessing the Pi (completely optional, but you will not be able to play Minecraft on the Pi)

\* Most of this guide can be completed on any computer running Debian. The server optimization and tuning is what is specifically Pi oriented.
### So what's the deal with Linux, why are we running a weird fork of it instead of Windows?
> [!NOTE]
> This section is intended for people who haven't really used Linux or don't really get what it's about. If that's not you, skip this!
> It's probably the most opinionated part of this guide, so please put down your pitchforks.

Linux fits in a weird spot in the OS spectrum. On one hand you have Apple's macOS which aims to deliver every user a perfect experience. As a result, there's relatively limited customization. Windows is a bit more freedom of customization and control at the expense of reliability. I love my Windows box but there's a non-zero chance that something won't work the way it should.

Linux, however, says screw all that. You have absolute and complete control over everything you want to control. That does mean that you can just kinda...break it, but that's worth it; anything you could break you have to do pretty intentionally. The downside is that to get that level of control, you have to learn not just the [command line](#command-line-crash-course) but also how operating systems and processes work in general. It's worth it, I promise. You're learning not only a new skill but a whole swath of new terms and ways of thinking about things. It will come, and this is a very, very verbose guide, so you should have a good basis.

For this project, we're using Linux because it's free and pretty light in terms of space and performance; it can run on less powerful hardware, which makes it perfect for Raspberry Pis (and older computers).
## Configuring the Pi
Starting this step I assume that you have a Pi and all its parts, including a microSD running Raspbian (Raspberry Pi OS). 

Make sure the Pi is powered off. Put the SD card into the Pi, connect it to a monitor, keyboard, and mouse, and power it up! You should be greeted by the splash screen and the setup. Go through the setup, but maybe save customizing everything to your liking till after the next section.

Get the Pi on the Wifi or Ethernet, it'll need to access the internet.

Install Java 25 by following the "Ubuntu/Debian" steps on guide: https://docs.papermc.io/misc/java-install. It's for Paper, but Purpur is a fork of Paper so no trouble there.

### Disabling the GUI (recommended)
> [!NOTE]
> If you're not confident/willing to put in a little brain power to learning command-line editors such as Vim or Nano skip this step!

Running a Graphical User Interface (GUI)--the desktop and visual programs as opposed to pure command line--isn't very taxing for a Pi, but the more processing power we can free up the better. If you choose to skip it, edit files in whatever text editor you like. My Pi shipped with 3 separate ones of varying degrees of complexity.

If you choose to disable the GUI, select "boot into command line", rather than "boot into GUI". This is known as booting "headless". You can always re-enable this if you end up using the Pi for something else by running `sudo raspi-config`.

## Downloading .jar files and initizalizing the server on your workstation
> [!NOTE]
> This step assumes you have access to any other computer that is more power than the Pi. If that isn't the case, follow these instructions on your Pi.
> I completed them on my Windows workstation.

### First run
Get the [.jar file from Purpur](https://purpurmc.org/docs/purpur/#downloads). I ran the latest supported version, which is 1.20.6. Make a folder called `Minecraft_server` and put the .jar in it. Open the Terminal app or just Command Prompt. `cd` into the `Minecraft_server` directory. `touch start.bat` to create a BATCH (Windows scripting) file. Edit the .bat in notepad and put the following code inside it. **Make sure you change the SERVER_NAME parameter to match that of your .jar file.**

```
java -Xms4096M -Xmx4096M -jar (JAR_NAME).jar --nogui
```

This uses `java` to open `(JAR_NAME).jar` with `4096M` of memory allocated (4GB) and with `no-gui`. The first time this .bat is run, it will generate a world and begin running it locally. If you stop the server and run the command again, it'll just start the server without re-generating anything.

Start the server by typing `start.ba<Tab>` and hitting enter. The server will spool up in about 30 seconds.

### Finding a good starting area
Launch Minecraft with the same version and Direct Connect to `localhost`. Run around and see if you like the spawn area. If you don't:
1. Stop the server by typing `/stop` in Minecraft or `stop` into the server console.
2. Delete the `world` folder that was created
3. Re-run the .bat and reconnect

### Pre-generating the world with Chunky
Once you've found a starting area you like, complete the following steps (copied verbatim from a [server optimization guide](https://github.com/YouHaveTrouble/minecraft-optimization?tab=readme-ov-file#map-pregen))<sup>more on that later</sup>:

------------
Map pregeneration, thanks to various optimizations to chunk generation added over the years is now only useful on servers with terrible, single threaded, or limited CPUs. Though, pregeneration is commonly used to generate chunks for world-map plugins such as Pl3xMap or Dynmap.

If you still want to pregen the world, you can use a plugin such as [Chunky](https://github.com/pop4959/Chunky) to do it. Make sure to set up a world border so your players don't generate new chunks! Note that pregenning can sometimes take hours depending on the radius you set in the pregen plugin. Keep in mind that with Paper and above your tps will not be affected by chunk loading, but the speed of loading chunks can significantly slow down when your server's cpu is overloaded.

It's key to remember that the overworld, nether and the end have separate world borders that need to be set up for each world. The nether dimension is 8x smaller than the overworld (if not modified with a datapack), so if you set the size wrong your players might end up outside of the world border!

**Make sure to set up a vanilla world border (`/worldborder set [diameter]`), as it limits certain functionalities such as lookup range for treasure maps that can cause lag spikes.**

------------

I set up a 1000 block radius with Chunky. That's a good enough size that you can sprint all out for a bit before hitting the border.

### Getting your completed files onto the Pi
> [!NOTE]
> If you completed the Chunky steps on the Pi already, skip this step.

Once Chunky is complete, shut down the server. We're going to use the terminal to securely copy (`scp`) the files from your workstation to your Pi. This starts to get into networking a little bit, so it may take some tweaking. When computers communicate, they do so using IP (Internet Protocol) addresses. This is like a house address for a computer. Due to firewalls and routers, computers on your Wifi are going to be on a different "network" than those connected directly via Ethernet.

Due to this fact, it's far easier to `scp` from a wired connection to a wireless one. If both are wireless or both are Ethernet, direction doesn't matter.

My workstation is wired and my Pi is wireless, so I'll explain that setup first.
#### Wired workstation -> Wireless Pi
<details>
 
To find the IP of your Pi, you'll need to type `ip a` into the console.

```
quiz@raspberry-pi:~ $ ip a

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN group default qlen 1000
    link/ether 2c:cf:67:1f:19:8e brd ff:ff:ff:ff:ff:ff
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 2c:cf:67:1f:19:8f brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.113/24 brd 192.168.0.255 scope global noprefixroute wlan0
       valid_lft forever preferred_lft forever
    inet6 fe80::78da:7a65:d220:ac4f/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```
Brief networking explanation: sections 1, 2, and 3 each refer to a different networking device inside of your computer. In my case, 1 is loopback, 2 is Ethernet and 3 is Wireless Local Area Network 0 (Wifi). My Pi wasn't connected to Ethernet, so I suspect that that was an internal hardware connection like loopback is.

Anyway, we're trying to find our wireless IP so we want to look at section 3:
```
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 2c:cf:67:1f:19:8f brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.113/24 brd 192.168.0.255 scope global noprefixroute wlan0
       valid_lft forever preferred_lft forever
    inet6 fe80::78da:7a65:d220:ac4f/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```
The line starting with `inet` is what we want. The IP of the Pi is `192.168.0.113`. Write this number down and label it as `PI_IP` so you don't forget.

On your Windows PC, launch Terminal/Command Prompt. Navigate to the **parent directory** of the `Minecraft_Server` folder that you ran Chunky in. So if the path is `C:/Users/Quiz/Documents/Minecraft_Server`, navigate to `Documents`. The command I would run is `scp -r Minecraft_Server quiz@192.168.0.113:~/mc/pre_gen_server`. This would prompt you for the Pi's password and then `r`ecursively copy the directory `Minecraft_Server` to the directory `/home/quiz/mc/pre_gen_server` (which `scp` will create if it is not present) on the computer listed with `192.168.0.113`. It may take a minute or two, depending on connection speed and file size.

The general form is `scp -r (local_destination_to_transfer) (pi_username)@(PI_IP):~/path/to/server/directory`

Confirm that the transfer worked by entering the Pi's console and running `ls ~/mc`. You should see the server directory listed there.
</details>

#### Wired Pi <- Wireless workstation
<details>
 
On your Windows PC, launch Terminal/Command Prompt. Type in `ipconfig` and you should get a long output that contains a section like this:

```
Wireless LAN adapter Wi-Fi:

   Connection-specific DNS Suffix  . : [redacted for privacy]
   Link-local IPv6 Address . . . . . : [redacted for privacy]
   IPv4 Address. . . . . . . . . . . : 10.140.248.114
   Subnet Mask . . . . . . . . . . . : [redacted for privacy]
   Default Gateway . . . . . . . . . : [redacted for privacy]
```
Write down the IPv4 address and label it `WORKSTATION_IP`.

On your Pi, `cd` to the location you want the new directory stored in. For me, that would be `cd ~/mc`. Remember, we're copying a directory, not a file, so we don't need to create the destination directory ourselves. Next, run `scp`. The command I would run is `scp -r Quiz@10.140.248.114:C:\Users\Quiz\Documents\Minecraft_Server .`. This would prompt you for the PC's password and then `r`ecursively copy the directory `Minecraft_Server` to the directory `.` (current directory) off of the computer listed with `WORKSTATION_IP`. It may take a minute or two, depending on connection speed and file size.

The general form is `scp -r (workstation_username)@(WORKSTATION_IP):(C:\path\to\server\) .` Note that Windows uses `\` and allows spaces in file and directory names whereas Linux uses `/` and does not allow spaces. I would just copy the path and paste it rather than retyping it.

Confirm that the transfer worked by entering the Pi's console and running `ls ~/mc`. You should see the server directory listed there.
</details>

## Tuning the server
What makes a server perform better is a mystical and arcane formula, known only to Microsoft and [this guy, who wrote a full optimization guide!](https://github.com/YouHaveTrouble/minecraft-optimization)<sup>Later is now!</sup>. I'm gonna explain a little bit about how the guide is formatted, then send you off to go do it. 

You should read the Intro but skip the Prep. We're using Purpur, so no need to pick another `.jar`.

The Config section is broken into 4 categories. Each category is further sorted by which file you edit. Make sure you're searching for the right changes in the right file! Running a Purpur server means we don't get a `pufferfish.yml` so you should ignore those sections.


<details>
 <summary>Guide index:</summary>
 
```
Intro
Preparation
Config
   Networking
      server.properties
      purpur.yml
   Chunks
       server.properties
       spigot.yml
       paper-world-configuration
       pufferfish.yml
   Mobs
       bukkit.yml
       spigot.yml
       paper-world-configuration
       pufferfish.yml
       purpur.yml
   Misc
       spigot.yml
       paper-world-configuration
       pufferfish.yml
       purpur.yml
```

 </details>

This is an excellent time to practice Vim. Remember to open a file in Vim:
 
```
vim (filename)
```

To search in Vim: `<Ctrl+C><:></>(string_to_search)<Enter>` and then `<n>` will jump forward to the next occurrence and `<Shift+n>` will jump back.

I have followed the guide and provided the files in the directory `no_trouble_standard_config_files`.

### My own tuning

I found that the optimized settings are, potentially, a little too optimized. I was getting perfect performance on the Pi with it, but the experience was lacking. Night had too few mobs and the view distance was way too close. So, I de-optimized them a little. I'm going to list the settings that I changed (and why). If you just want to try out my settings, I've included them in `quizs_config_files`.

<details>
<summary>bukkit.yml</summary>
I changed the following:
 
 ```
spawn-limits:
  monsters: 20 -> 30
  animals: 5 -> 7
  water-animals: 2 -> 3
  water-ambient: 2 -> 20
  ambient: 1 -> 10

ticks-per:
  monster-spawns: 10 -> 1
  animal-spawns: 400 -> 10
  water-spawns: 400 -> 1
  water-ambient-spawns: 400 -> 1
  water-underground-creature-spawns: 400 -> 10
  ambient-spawns: 400 -> 200

 ```

Raising the spawn limits allows for more life close to the player. Lowering ticks-per results in more attempts to spawn mobs that get killed.

</details>

<details>
<summary>paper-world-defaults.yml</summary>

`entity-per-chunk-save-limit`s go to -1. I didn't find that this saved any performance, but it made getting experiences and such annoying.


&nbsp;


`despawn-ranges` are adjusted according to the simulation distance formula provided.


&nbsp;


`max-entity-collisions: 2 -> 3`. Getting crammed to death by two chickens wasn't fun (and again messed with villagers), so I upped the limit slightly.


&nbsp;


`update-pathfinding-on-block-update: false -> true` for villager pathfinding and fighting mobs.


&nbsp;


```
  behavior:
    villager:
      validatenearbypoi: 60 -> -1
      acquirepoi: 120 -> delete the line
```
`aquirepoi` is removed in recent Paper configs and `validatenearbypoi` hampered villagers, so up it goes.


&nbsp;


`alt-item-despawn-rate`s were all deleted except cobblestone. Nothing else appears in such great quantities as to impact the performance of the server.

&nbsp;



```
redstone-implementation: ALTERNATE_CURRENT -> VANILLA

```
Didn't want common builds found online to break. If you use redstone a lot, consider changing this back to AC.

&nbsp;

```
hopper:
  ignore-occluding-blocks: true -> false
```
See redstone above.


&nbsp;


```
tick-rates:
  mob-spawner: 2 -> 1
```
Mob spawners didn't impact performance, so I dropped this to be more like Vanilla.


&nbsp;


```
non-player-arrow-despawn-rate: 20 -> 4
```
Saves performance and it's annoying to try and pick up arrows that aren't yours.


&nbsp;


```
creative-arrow-despawn-rate: 20 -> default
```
If I go into Creative mode to shoot arrows at someone, I want them to feel pincushioned.
</details>

<details>
 <summary>purpur.yml</summary>

```
entities-can-use-portals: false -> true
```
Happens incredibly infrequently, but cool when it does.

&nbsp;

```
search-radius:
  acquire-poi: 16 -> 48
```
Villagers could only detect jobsite blocks that were under their nose.

&nbsp;


</details>

<details>
 <summary>server.properties</summary>
 
```
network-compression-threshold=256 -> 512
```
Bandwidth is pretty good nowadays, and we need to save the CPU as much as we can.
 
&nbsp;

```
simulation-distance=4 -> 6
view-distance=7 -> 10
```
It felt like playing during a snowstorm and raising these numbers didn't tank performance, even at high player counts.
 
&nbsp;

```
max-players=20 -> 5
white-list=false -> true
```
Two security-oriented changes!
</details>

<details>
 <summary>spigot.yml</summary>
 
```
mob-spawn-range: 3 -> 6
```
This way all the mobs don't just get dropped on your head.
 
&nbsp;



```
tick-inactive-villagers: false -> true
```
Messed with villagers.

 
&nbsp;

```
nerf-spawner-mobs: true -> false
```
Boring and spawners didn't impact performance.

 
&nbsp;

```
hopper-check: 8 -> 1
```
Needs many hoppers to impact performance, but is annoying to have hoppers slowed.

</details>

## Port fowarding the router
Port forwarding is the act of exposing a port to the wider internet. Each router will have its own way of doing things, so Google how to port forward, there are many tutorials. The default Minecraft port is 25565, so I'd recommend choosing another number like 25665--just to avoid port scrapers. Opening a port is inherently unsafe. If you don't understand the risks, do some reading on the basics of networking. 

Alternatively, accept this analogy: right now, your internet traffic is more or less anonymous. Opening the port and hosting a public Minecraft server is like hanging a sign in your bedroom window that says "Rob me!". Does it make you more vulnerable? Only because you're calling attention to yourself. Does it invite more robbers? No, not more than any other house would. Is it going to make passerby stop and stare, maybe poke around a bit to see what's going on? Absolutely.

## Running the server
`cd` into the server's folder and create a file titled `start.sh`. Make the contents:
```
#!/bin/bash
# ~/mc/(world_name)/start.sh


java -Xms4096M -Xmx4096M -jar (JAR_NAME).jar --nogui

```
Then run `sudo chmod +x start.sh` to make it executable. You should be prompted for your sudo password. Now, you can run `./start.sh`. The server will start and other people should be able to connect. Congratulations, you have created a Minecraft server!
