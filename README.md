WakeOnLan
=========

Wakes computers through Magic Packets.

## Installing
Installing `wake` is rather simple.
First, clone this repo:
```
$ git clone https://github.com/victorgama/WakeOnLan.git
```
Now, `cd` to the cloned repo and run `make`.
You may want to run `make` using `sudo`, since it symlinks to `/usr/bin`
```
$ cd WakeOnLan && sudo make
```
Done!

## Usage
`wake` targets local networks, althrough it may also works through external networks.
First, you need to register a new device, providing it's MAC address, IP address and a name.

```
$ wake register aa:bb:cc:dd:ee:ff 192.168.1.127 Vito\'s MacBook Pro
Success: Registered device 'Vito's MacBook Pro' with MAC Address aa:bb:cc:dd:ee:ff and IP 192.168.1.127
```

You can get a list of registered devices trough `wake list`:
```
$ wake list
+-------------------+-------------------+---------------+
| Name              | MAC Address       | IP Address    |
+-------------------+-------------------+---------------+
| Vito's MacBook Pro | aa:bb:cc:dd:ee:ff | 192.168.1.127 |
+-------------------+-------------------+---------------+
```

And query their status through `wake status`:
```
$ wake status
Querying devices...
+--------------------+-------------------+---------------+--------+
| Name               | MAC Address       | IP Address    | Status |
+--------------------+-------------------+---------------+--------+
| Vito's MacBook Pro | aa:bb:cc:dd:ee:ff | 192.168.1.127 | :(     |
+--------------------+-------------------+---------------+--------+
```

To wake a registered device, run `wake <device name>`:

```
$ wake Vito\'s MacBook Pro
Waking up Vito's MacBook Pro... OK

$ wake status
Querying devices...
+--------------------+-------------------+---------------+--------+
| Name               | MAC Address       | IP Address    | Status |
+--------------------+-------------------+---------------+--------+
| Vito's MacBook Pro | aa:bb:cc:dd:ee:ff | 192.168.1.127 | :D     |
+--------------------+-------------------+---------------+--------+
```