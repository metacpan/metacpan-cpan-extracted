# Virani

## Installation & Setup

Install various Perl requiremnets. This can be taken care of with
command below.

```shell
    cpanm Virani
```

Configure it.

For example on FreeBSD if you have daemonlogger set up something like
below.

```shell
    daemonlogger_enable="YES"
    daemonlogger_flags="-f /usr/local/etc/daemonlogger.bpf -d -l /var/log/daemonlogger -t 120"
```

Then a basic config would be like below.

```toml
    default_set='default'
    allowed_subnets=["192.168.14.0/23", "127.0.0.1/8"]
    [sets.default]
    path='/var/log/daemonlogger'
    regex='(?<timestamp>\d\d\d\d\d\d+)(\.pcap|(?<subsec>\.\d+)\.pcap)$'
    strptime='%s'
```

For more information on the config file, see the POD for Virani.

## Usage

A example grabbing port 53 traffic below can be done like the
following.

```shell
    virani -s 2023-02-27T11:00:18 -e 2023-02-27T11:31:18 port 53
```

The time may also be specified like below.

```
now       current time
now-30    30 seconds ago
now-30m   30 minutes ago
now-30h   30 hours ago
now-30w   30 weeks ago
```

So if you wanted to find all port 53 traffic in the last minute, you
could do somethiing like below.

```shell
    virani -s now-1m -e now port 53
```

The help info for virani is as below. For more info check out the POD
for the module Virani and the script Virani.

```
--help            Print this.
-h                Print this.

--version         Print version.
-v                Print version..

-r <remote>       Remote URL or config file for remote info.

-a <apikey>       API key for remote URL if needed.

-f <filter>       Filter for use with tshark or tcpdump.

-t <type>         tcpdump or tshark
                  Default :: tcpdump

-t <set>          Set to use. If undef, uses whatever the default is.
                  Default :: undef

--config <config> Config file to use.
                  Default :: /usr/local/etc/virani.toml

-s <timestamp>    Start timestamp. Any format supported by
                  Time::Piece::Guess is usable.

-e <timestamp>    End timestamp. Any format supported by
                  Time::Piece::Guess is usable.

-w <output>       The file to write the PCAP to.
                  Default :: out.pcap

--nc              If cached, do not use it.

-k                Do not check the SSL cert for HTTPS for remote.
```

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999
