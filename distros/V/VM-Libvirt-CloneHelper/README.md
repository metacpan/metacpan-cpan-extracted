# VM-Libvirt-CloneHelper

Create a bunch of cloned VMs in via libvirt.

## SYNOPSIS

```
clonehelper [-f <config>] [-n <name>] -a <action>
```

## DESCRIPTION

The basic work flow for this is like below.

```
delete
clone
start
wait a bit till they are all started
snapshot
shutdown
```

This can automatically be done via using the action recreate. If you
wish to do it for all, you likely want to use recreate_all.

A single VM may be acted upon via using the -n switch.

## SWITCHES

### -a action

The action to perform.

### -f config

The config to use.

### -n name

Act specifically on this VM instead of them all.

## ACTIONS

### list

Print a JSON dump of VMs, maps, and IPs.

### start

Start all the VM clones.

### stop

Stop all the VM clones.

### clone

Generate the VM clones.

### delete

Delete all the VM clones.

### net_xml

Generate the XML config and print it.

### net_redefine

Remove and re-add the network using the generated config.

### recreate

Recreate the VMs.

### recreate_all

Recreate the VMs, doing them one at a time.

### snapshot

Snapshot all the VM clones.

## CONFIG

The config format is a INI file.

The variable/value defaults are shown below.

```ini
net=default
# Name of the libvirt network in question.
 
blank_domains=/usr/local/etc/clonehelper/blank_domains
# List of domains to blank via setting 'dnsmasq:option value='address=/foo.bar/'.
# If not this file does not exist, it will be skipped.
 
net_head=/usr/local/etc/clonehelper/net_head
# The top part of the net XML config that that dnsmasq options will be
# sandwhiched between.
 
net_tail=/usr/local/etc/clonehelper/net_tail
# The bottom part of the net XML config that that dnsmasq options will
# be sandwhiched between.
 
windows_blank=1
# Blank commonly used MS domains. This is handy for reducing network noise
# when testing as well as making sure they any VMs don't do something like
# run updates when one does not want it to.
 
mac_base=00:08:74:2d:dd:
# Base to use for the MAC.
 
ipv4_base=192.168.1.
# Base to use for the IPs for adding static assignments.
 
start=100
# Where to start in set.
 
to_clone=baseVM
# The name of the VM to clone.
 
clone_name_base=cloneVM
# Base name to use for creating the clones. 'foo' will become 'foo$current', so
# for a start of 100, the first one would be 'foo100' and with a count of 10 the
# last will be 'foo109'.
 
count=10
# How many clones to create.
 
snapshot_name=clean
# The name to use for the snapshot.
 
wait=360
# How long to wait if auto-doing all.
```

## INSTALL

- File::Slurp
- Config::Tiny

Via CPANM

```shell
cpanm VM::Libvirt::CloneHelper
```

Via source...

```shell
perl Makefile.PL
make
make test
make install
```
