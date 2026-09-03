# Intro to Linux
I am not an expert by any means, but the following sections should get you up to speed.

## Command Line crash course
[Jump to Command Line Quick Reference](#command-line-quick-reference)

You're gonna have to know some things about the command line in order to stay sane. 

If you're setting up a server, you've probably messed around with Minecraft commands, such as `/tp`. When you open the chat and type, you're interacting with the server on a command line, not graphically. In this case, non-graphical means that there's no cursor or windows to navigate. 

When running headless Linux, you interact with every* system by typing commands in. The `/tp` command can take "arguments", or targets. `/tp Alice Bob` will teleport target Alice to target Bob. Linux commands sometimes also have arguments. And, like in Minecraft, if you type in a target that doesn't exist, the command will throw an error. If no error is thrown, generally nothing will print. This is good! No output is good output.

In Linux, commands are frequently shortened to representative letters; just like `/tp` for `t`ele`p`ort, Linux has `cp` for `c`o`p`y. Notice that Linux commands do not have a `/` before them. That's because in Minecraft, you can either send text in chat or type commands, so you need a way to distinguish between the two. In Linux, you just type commands.

Let's say you're in a directory[^1] with one text file: `Alice.txt`. If you want to make a copy of `Alice.txt` and store it in `Alice_backup.txt`, you would type `cp Alice.txt Alice_backup.txt`.
[^1]:In Linux, the things we know as folders are referred to as directories. Much like a building directory, a folder is really just a list of files.

### Worked example
Now that you've seen how it flows, let's do a worked example. We're going to make a directory titled `minecraft_servers`, navigate into it, create `DEFAULT_README.txt` file and add some text to it. Then, we'll create a `purpur_defaults` directory, copy the `DEFAULT_README.txt` into it and rename it `README_PURPUR_DEFAULTS.txt` before editing it again. I'll go line by line and explain, then show the entire block at the end.

Note that my command prompt renders here as `quiz@raspberry-pi:~ $ `. The commands are the text after the `$`. Yours may include the current path, something like: `(user)@(machine):~/your/current/path$`. Neither will impact functionality.
<details>
 <Summary>Line by line example</Summary>

 ```
quiz@raspberry-pi:~ $ mkdir minecraft_servers
```
Make a directory in the current directory and title it `minecraft_servers`

```
quiz@raspberry-pi:~ $ cd minecraft_servers/
```
Change to the `minecraft_servers` directory. In this case, the final `/` is optional. It appeared because I actually typed `cd mine<Tab>`, which autocompletes.

```
quiz@raspberry-pi:~ $ ls
```
List all the files in this directory. There's no output because it's empty! We just made it.

```
quiz@raspberry-pi:~ $ touch DEFAULT_README.txt
```
Create the `DEFAULT_README.txt` file. No output is good output, so we assume the file is created successfully.

```
quiz@raspberry-pi:~ $ ls
DEFAULT_README.txt
```
List all the files in this directory. The output shows that there's just one file, as expected.

```
quiz@raspberry-pi:~ $ vim DEFAULT_README.txt
```
This launches into the Vim editor, which has a learning curve the size and shape of a brick wall. [My attempt at a tutorial](#vim-crash-course). Your favourite online resource probably has a tutorial.

For now, just hit `<i>` and then type this: `This is a [version] server running: [plugins].` Then hit `<Ctrl+C>` before typing: `<:wq>`. Hit `<Enter>` to save and quit.

This enters `i`nsert mode which lets you type text as normal. You then exit insert mode with `<Ctrl+C>`. Now in `Normal` mode, you send Vim a command with `:`. The command is `w`rite and `q`uit, using `<Enter>` to send.

```
quiz@raspberry-pi:~ $ mkdir purpur_defaults
```
Make a directory in the current directory and title it `purpur_defaults`

```
quiz@raspberry-pi:~ $ cp DEFAULT_README.txt purpur_defaults/
```
Copy the `DEFAULT_README.txt` from this directory and place it in `purpur_defaults`. When the destination filename is unspecified, it will use the source filename. 

You could also replace the second argument `purpur_defaults/` with `purpur_defaults/README_PURPUR_DEFAULTS.txt` which would copy `DEFAULT_README.txt` and store it in `purpur_defaults/` with the name `README_PURPUR_DEFAULTS.txt`. Doing so would remove the need for the `mv` command that happens next.

```
quiz@raspberry-pi:~ $ cd purpur_defaults/
```
Change to the `purpur_defaults` directory. This is technically optional; all commands can operate on files that are in other directories, it's just more typing. 

Eg: `cp minecraft_servers/DEFAULT_README.txt minecraft_servers/purpur_defaults/` vs the cp command above.

```
quiz@raspberry-pi:~ $ mv DEFAULT_README.txt README_PURPUR_DEFAULTS.txt
```
Move `DEFAULT_README.txt` to the file `README_PURPUR_DEFAULTS.txt`, effectively renaming it.

```
quiz@raspberry-pi:~ $ vim README_PURPUR_DEFAULTS.txt
```
Edit the new README with Vim. Press `<i>` to enter `i`nsert mode. Edit the text to say: `This is a Purpur server running full defaults. Do not edit this directory!`. Exit `i`nsert mode (`<Ctrl+C>`) then save and exit (`:wq<Enter>`).

```
quiz@raspberry-pi:~ $ cat README_PURPUR_DEFAULTS.txt
This is a Purpur server running full defaults. Do not edit this directory!
```
This prints the contents of `README_PURPUR_DEFAULTS.txt` to the console. Just a verification that our changes saved.

```
quiz@raspberry-pi:~ $ cd ..
```
Change directory up to the parent folder, which is `minecraft_servers`.

```
quiz@raspberry-pi:~ $ ls
DEFAULT_README.txt  purpur_defaults
```
List the contents of the current directory. You can see the first README we created, as well as the `purpur_defaults` directory. They should be colour-coded, for me blue is a directory and no color is a file.

```
quiz@raspberry-pi:~ $ ls purpur_defaults/
README_PURPUR_DEFAULTS.txt
```
List the contents of the `purpur_defaults/` directory. You can see the second README.


&nbsp;

With that, you've done it! You've survived your first journey into the Linux command line. Take a break and have some water, it can only get easier.
</details>
<details>
<Summary>Full command block</Summary>
 
```
quiz@raspberry-pi:~ $ mkdir minecraft_servers
quiz@raspberry-pi:~ $ cd minecraft_servers/
quiz@raspberry-pi:~ $ ls
quiz@raspberry-pi:~ $ touch DEFAULT_README.txt
quiz@raspberry-pi:~ $ ls
DEFAULT_README.txt
quiz@raspberry-pi:~ $ vim DEFAULT_README.txt
quiz@raspberry-pi:~ $ mkdir purpur_defaults
quiz@raspberry-pi:~ $ cp DEFAULT_README.txt purpur_defaults/
quiz@raspberry-pi:~ $ cd purpur_defaults/
quiz@raspberry-pi:~ $ mv DEFAULT_README.txt README_PURPUR_DEFAULTS.txt
quiz@raspberry-pi:~ $ vim README_PURPUR_DEFAULTS.txt
quiz@raspberry-pi:~ $ cat README_PURPUR_DEFAULTS.txt
This is a Purpur server running full defaults. Do not edit this directory!
quiz@raspberry-pi:~ $ cd ..
quiz@raspberry-pi:~ $ ls
DEFAULT_README.txt  purpur_defaults
quiz@raspberry-pi:~ $ cd purpur_defaults/
quiz@raspberry-pi:~ $ ls purpur_defaults/
README_PURPUR_DEFAULTS.txt
```

</details>

### Command line quick reference
`~` is a substitute for `/home/(user_name)`, such as `/home/quiz`

`.` refers to the current directory. `..` is the directory above the current.

`<Tab>` will auto complete.

All flags are optional.

|Command | Flags | Targets| Usage|
|---|---|---|---|
| `cp` |`-r`ecursive|`SOURCE` `DESTINATION` | Copy file `source` to file `destination`. `-r` will copy directories.|
| `mv` |`-n`o clobber|`SOURCE` `DESTINATION`| Move file `source` to file `destination`.<br>This can also be used to "rename" files.<br>`-n` will prevent you from overwriting an existing file.|
| `ls` |`-a`ll<br>`-l`ong|`[FILE]`| | Lists files in the current directory. |
| `cd` ||`DESTINATION`|Change directory to `destination`.|
|`touch`||`DESTINATION`| Create file `destination`|
|`mkdir`||`DIRECTORY`|Create directory `destination`|
|`cat`||`FILE`|Print the **entire** contents of `destination` to the console.<br>Will con`cat`enate the file contents to the standard output, (which is the console).|
|`less`||`FILE`|Display a paginated version of `destination`'s contents.<br>`<Space>` will jump a page and `<q>` will exit.<br>`<Arrow keys>` will move line by line.|
|`scp`<br>(loc->rem)|`-r`ecursive|`LOCAL_SOURCE` `[DEST_USR@]DEST_IP`:`REMOTE_DEST` |Securely copy file `LOCAL_SOURCE` to `REMOTE_DEST` which lives on `DEST_IP`.<br>`DEST_USR` is optional and will password prompt.|
|`scp`<br>(rem->loc)|`-r`ecursive|`[SOURCE_USR@]SOURCE_IP`:`REMOTE_SOURCE` `LOCAL_DEST` |Securely copy file `REMOTE_SOURCE` which lives on `SOURCE_IP` to `LOCAL_DEST`|
