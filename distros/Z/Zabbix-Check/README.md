# NAME

Zabbix::Check - System and service checks for Zabbix

# VERSION

version 1.10

# SYNOPSIS

System and service checks for Zabbix

        UserParameter=cpan.zabbix.check.version,/usr/bin/perl -MZabbix::Check -e_version

### version

gets Zabbix::Check version

## Disk

Zabbix check for disk

        UserParameter=cpan.zabbix.check.disk.discovery,/usr/bin/perl -MZabbix::Check::Disk -e_discovery
        UserParameter=cpan.zabbix.check.disk.bps[*],/usr/bin/perl -MZabbix::Check::Disk -e_bps -- $1 $2
        UserParameter=cpan.zabbix.check.disk.iops[*],/usr/bin/perl -MZabbix::Check::Disk -e_iops -- $1 $2
        UserParameter=cpan.zabbix.check.disk.ioutil[*],/usr/bin/perl -MZabbix::Check::Disk -e_ioutil -- $1

### discovery

discovers disks

### bps $1 $2

gets disk I/O traffic in bytes per second

$1: _device name, eg: sda, sdb1, dm-3, ..._

$2: _type: read|write|total_

### iops $1 $2

gets disk I/O transaction speed in transactions per second

$1: _device name, eg: sda, sdb1, dm-3, ..._

$2: _type: read|write|total_

### ioutil $1 $2

gets disk I/O utilization in percentage

$1: _device name, eg: sda, sdb1, dm-3, ..._

## Supervisor

Zabbix check for Supervisor service

        UserParameter=cpan.zabbix.check.supervisor.installed,/usr/bin/perl -MZabbix::Check::Supervisor -e_installed
        UserParameter=cpan.zabbix.check.supervisor.running,/usr/bin/perl -MZabbix::Check::Supervisor -e_running
        UserParameter=cpan.zabbix.check.supervisor.worker_discovery,/usr/bin/perl -MZabbix::Check::Supervisor -e_worker_discovery
        UserParameter=cpan.zabbix.check.supervisor.worker_status[*],/usr/bin/perl -MZabbix::Check::Supervisor -e_worker_status -- $1

### installed

checks Supervisor is installed: 0 | 1

### running

checks Supervisor is installed and running: 0 | 1 | 2 = not installed

### worker\_discovery

discovers Supervisor workers

### worker\_status $1

gets Supervisor worker status: RUNNING | STOPPED | ...

$1: _worker name_

## RabbitMQ

Zabbix check for RabbitMQ service

        UserParameter=cpan.zabbix.check.rabbitmq.installed,/usr/bin/perl -MZabbix::Check::RabbitMQ -e_installed
        UserParameter=cpan.zabbix.check.rabbitmq.running,/usr/bin/perl -MZabbix::Check::RabbitMQ -e_running
        UserParameter=cpan.zabbix.check.rabbitmq.vhost_discovery[*],/usr/bin/perl -MZabbix::Check::RabbitMQ -e_vhost_discovery -- $1
        UserParameter=cpan.zabbix.check.rabbitmq.queue_discovery[*],/usr/bin/perl -MZabbix::Check::RabbitMQ -e_queue_discovery -- $1
        UserParameter=cpan.zabbix.check.rabbitmq.queue_status[*],/usr/bin/perl -MZabbix::Check::RabbitMQ -e_queue_status -- $1 $2 $3

### installed

checks RabbitMQ is installed: 0 | 1

### running

checks RabbitMQ is installed and running: 0 | 1 | 2 = not installed

### vhost\_discovery $1

discovers RabbitMQ vhosts

$1: _cache expiry in seconds, by default 0_

### queue\_discovery $1

discovers RabbitMQ queues

$1: _cache expiry in seconds, by default 0_

### queue\_status $1 $2 $3

gets RabbitMQ queue status using queue discovery cache

$1: _vhost name_

$2: _queue name_

$3: _type: ready|unacked|total_

## Systemd

Zabbix check for Systemd services

        UserParameter=cpan.zabbix.check.systemd.installed,/usr/bin/perl -MZabbix::Check::Systemd -e_installed
        UserParameter=cpan.zabbix.check.systemd.system_status,/usr/bin/perl -MZabbix::Check::Systemd -e_system_status
        UserParameter=cpan.zabbix.check.systemd.service_discovery[*],/usr/bin/perl -MZabbix::Check::Systemd -e_service_discovery -- $1
        UserParameter=cpan.zabbix.check.systemd.service_status[*],/usr/bin/perl -MZabbix::Check::Systemd -e_service_status -- $1

### installed

checks Systemd is installed: 0 | 1

### system\_status

gets Systemd system status: initializing | starting | running | degraded | maintenance | stopping | offline | unknown

### service\_discovery

discovers Systemd enabled services

$1: _regex of service name, by default undefined_

### service\_status $1

gets Systemd enabled service status: active | inactive | failed | unknown | ...

$1: _service name_

## Time

Zabbix check for system time

        UserParameter=cpan.zabbix.check.time.epoch,/usr/bin/perl -MZabbix::Check::Time -e_epoch
        UserParameter=cpan.zabbix.check.time.zone,/usr/bin/perl -MZabbix::Check::Time -e_zone
        UserParameter=cpan.zabbix.check.time.ntp_offset[*],/usr/bin/perl -MZabbix::Check::Time -e_ntp_offset -- $1 $2

### epoch

gets system time epoch in seconds

### zone

gets system time zone, eg: +0200

### ntp\_offset $1 $2

gets system time difference by NTP server

$1: _server, by defaut pool.ntp.org_

$2: _port, by default 123_

# INSTALLATION

To install this module type the following

        perl Makefile.PL
        make
        make test
        make install

from CPAN

        cpan -i Zabbix::Check

# DEPENDENCIES

This module requires these other modules and libraries:

- Switch
- FindBin
- Cwd
- File::Basename
- File::Slurp
- JSON
- Net::NTP
- Lazy::Utils

# REPOSITORY

**GitHub** [https://github.com/orkunkaraduman/Zabbix-Check](https://github.com/orkunkaraduman/Zabbix-Check)

**CPAN** [https://metacpan.org/release/Zabbix-Check](https://metacpan.org/release/Zabbix-Check)

# AUTHOR

Orkun Karaduman &lt;orkunkaraduman@gmail.com&gt;

# COPYRIGHT AND LICENSE

Copyright (C) 2016  Orkun Karaduman &lt;orkunkaraduman@gmail.com&gt;

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see &lt;http://www.gnu.org/licenses/&gt;.
