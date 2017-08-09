package Zabbix::Check;
=head1 NAME

Zabbix::Check - System and service checks for Zabbix

=head1 VERSION

version 1.12

=head1 SYNOPSIS

System and service checks for Zabbix

	UserParameter=cpan.zabbix.check.installed,/usr/bin/env bash -c "/usr/bin/env perl -MZabbix::Check 2>/dev/null; if [ \$? -eq 0 ]; then echo 1; else echo 0; fi"
	UserParameter=cpan.zabbix.check.version,/usr/bin/env perl -MZabbix::Check -e_version
	# Disk
	UserParameter=cpan.zabbix.check.disk.discovery,/usr/bin/env perl -MZabbix::Check::Disk -e_discovery
	UserParameter=cpan.zabbix.check.disk.bps[*],/usr/bin/env perl -MZabbix::Check::Disk -e_bps -- $1 $2
	UserParameter=cpan.zabbix.check.disk.iops[*],/usr/bin/env perl -MZabbix::Check::Disk -e_iops -- $1 $2
	UserParameter=cpan.zabbix.check.disk.ioutil[*],/usr/bin/env perl -MZabbix::Check::Disk -e_ioutil -- $1
	# Supervisor
	UserParameter=cpan.zabbix.check.supervisor.installed,/usr/bin/env perl -MZabbix::Check::Supervisor -e_installed
	UserParameter=cpan.zabbix.check.supervisor.running,/usr/bin/env perl -MZabbix::Check::Supervisor -e_running
	UserParameter=cpan.zabbix.check.supervisor.worker_discovery,/usr/bin/env perl -MZabbix::Check::Supervisor -e_worker_discovery
	UserParameter=cpan.zabbix.check.supervisor.worker_status[*],/usr/bin/env perl -MZabbix::Check::Supervisor -e_worker_status -- $1
	# RabbitMQ
	UserParameter=cpan.zabbix.check.rabbitmq.installed,/usr/bin/env perl -MZabbix::Check::RabbitMQ -e_installed
	UserParameter=cpan.zabbix.check.rabbitmq.running,/usr/bin/env perl -MZabbix::Check::RabbitMQ -e_running
	UserParameter=cpan.zabbix.check.rabbitmq.vhost_discovery[*],/usr/bin/env perl -MZabbix::Check::RabbitMQ -e_vhost_discovery -- $1
	UserParameter=cpan.zabbix.check.rabbitmq.queue_discovery[*],/usr/bin/env perl -MZabbix::Check::RabbitMQ -e_queue_discovery -- $1
	UserParameter=cpan.zabbix.check.rabbitmq.queue_status[*],/usr/bin/env perl -MZabbix::Check::RabbitMQ -e_queue_status -- $1 $2 $3
	# Systemd
	UserParameter=cpan.zabbix.check.systemd.installed,/usr/bin/env perl -MZabbix::Check::Systemd -e_installed
	UserParameter=cpan.zabbix.check.systemd.system_status,/usr/bin/env perl -MZabbix::Check::Systemd -e_system_status
	UserParameter=cpan.zabbix.check.systemd.service_discovery[*],/usr/bin/env perl -MZabbix::Check::Systemd -e_service_discovery -- $1
	UserParameter=cpan.zabbix.check.systemd.service_status[*],/usr/bin/env perl -MZabbix::Check::Systemd -e_service_status -- $1
	# Time
	UserParameter=cpan.zabbix.check.time.epoch,/usr/bin/env perl -MZabbix::Check::Time -e_epoch
	UserParameter=cpan.zabbix.check.time.zone,/usr/bin/env perl -MZabbix::Check::Time -e_zone
	UserParameter=cpan.zabbix.check.time.ntp_offset[*],/usr/bin/env perl -MZabbix::Check::Time -e_ntp_offset -- $1 $2
	# Redis
	UserParameter=cpan.zabbix.check.redis.installed,/usr/bin/env perl -MZabbix::Check::Redis -e_installed
	UserParameter=cpan.zabbix.check.redis.discovery,/usr/bin/env perl -MZabbix::Check::Redis -e_discovery
	UserParameter=cpan.zabbix.check.redis.running[*],/usr/bin/env perl -MZabbix::Check::Redis -e_running -- $1
	UserParameter=cpan.zabbix.check.redis.info[*],/usr/bin/env perl -MZabbix::Check::Redis -e_info -- $1 $2
	UserParameter=cpan.zabbix.check.redis.resptime[*],/usr/bin/env perl -MZabbix::Check::Redis -e_resptime -- $1

=head1 DISK

Zabbix check for disk

=head2 discovery

discovers disks

=head2 bps $1 $2

gets disk I/O traffic in bytes per second

$1: I<device name, eg: sda, sdb1, dm-3, ...>

$2: I<type: read|write|total>

=head2 iops $1 $2

gets disk I/O transaction speed in transactions per second

$1: I<device name, eg: sda, sdb1, dm-3, ...>

$2: I<type: read|write|total>

=head2 ioutil $1

gets disk I/O utilization in percentage

$1: I<device name, eg: sda, sdb1, dm-3, ...>

=head1 SUPERVISOR

Zabbix check for Supervisor service

=head2 installed

checks Supervisor is installed: 0 | 1

=head2 running

checks Supervisor is installed and running: 0 | 1 | 2 = not installed

=head2 worker_discovery

discovers Supervisor workers

=head2 worker_status $1

gets Supervisor worker status: RUNNING | STOPPED | ...

$1: I<worker name>

=head1 RABBITMQ

Zabbix check for RabbitMQ service

=head2 installed

checks RabbitMQ is installed: 0 | 1

=head2 running

checks RabbitMQ is installed and running: 0 | 1 | 2 = not installed

=head2 vhost_discovery $1

discovers RabbitMQ vhosts

$1: I<cache expiry in seconds, by default 0>

=head2 queue_discovery $1

discovers RabbitMQ queues

$1: I<cache expiry in seconds, by default 0>

=head2 queue_status $1 $2 $3

gets RabbitMQ queue status using queue discovery cache

$1: I<vhost name>

$2: I<queue name>

$3: I<type: ready|unacked|total>

=head1 SYSTEMD

Zabbix check for Systemd services

=head2 installed

checks Systemd is installed: 0 | 1

=head2 system_status

gets Systemd system status: initializing | starting | running | degraded | maintenance | stopping | offline | unknown

=head2 service_discovery

discovers Systemd enabled services

$1: I<regex of service name, by default undefined>

=head2 service_status $1

gets Systemd enabled service status: active | inactive | failed | unknown | ...

$1: I<service name>

=head1 TIME

Zabbix check for system time

=head2 epoch

gets system time epoch in seconds

=head2 zone

gets system time zone, eg: +0200

=head2 ntp_offset $1 $2

gets system time difference by NTP server

$1: I<server, by defaut pool.ntp.org>

$2: I<port, by default 123>

=head1 REDIS

Zabbix check for Redis service

=head2 installed

checks Redis is installed: 0 | 1

=head2 discovery

discovers Redis instances

=head2 running $1

checks Redis is installed and instance is running: 0 | 1 | 2 = not installed

$1: I<bind, by defaut 127.0.0.1:6379>

=head2 info $1 $2

gets info

$1: I<key>

$2: I<bind, by defaut 127.0.0.1:6379>

=head2 resptime $1

gets single GET command response time from Redis

$1: I<bind, by defaut 127.0.0.1:6379>

=cut
use strict;
use warnings;
use v5.10.1;
use JSON;
use Net::NTP;
use Lazy::Utils;


BEGIN
{
	require Exporter;
	our $VERSION     = '1.12';
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(zbx_encode zbx_decode print_discovery _version);
	our @EXPORT_OK   = qw();
}


our @zbx_specials = split(" ", q%\ ' " ` * ? [ ] { } ~ $ ! & ; ( ) < > | \# @%);


sub zbx_encode
{
	my $result = "";
	my ($str) = @_;
	return $result unless defined($str);
	for (my $i = 0; $i < length $str; $i++)
	{
		my $chr = substr $str, $i, 1;
		if (not $chr =~ /[ -~]/g or grep($_ eq $chr, (@zbx_specials, '%', ',')))
		{
			$result .= uc sprintf("%%%x", ord($chr));
		} else
		{
			$result .= $chr;
		}
	}
	return $result;
}

sub zbx_decode
{
	my $result = "";
	my ($str) = @_;
	return $result unless defined($str);
	my ($i, $len) = (0, length $str);
	while ($i < $len)
	{
		my $chr = substr $str, $i, 1;
		if ($chr eq '%')
		{
			return $result if $len-$i-1 < 2;
			$result .= chr(hex(substr($str, $i+1, 2)));
			$i += 2;
		} else
		{
			$result .= $chr;
		}
		$i++;
	}
	return $result;
}

sub print_discovery
{
	my @items = @_;
	my $discovery = {
		data => [
			map({
				my $item = $_;
				my %newitem = map({
					my $key = $_;
					my $val = $item->{$key};
					my $newkey = zbx_encode($key);
					$newkey = uc("{#$newkey}");
					my $newval = zbx_encode($val);
					$newkey => $newval;
				} keys(%$item));
				\%newitem;
			} @items),
		],
	};
	my $result = to_json($discovery, {pretty => 1});
	print $result;
	return $result;
}

sub _version
{
	my $result = "";
	$result = $Zabbix::Check::VERSION;
	print $result;
	return $result;
}


1;
__END__
=head1 INSTALLATION

To install this module type the following

	perl Makefile.PL
	make
	make test
	make install

from CPAN

	cpan -i Zabbix::Check

=head1 DEPENDENCIES

This module requires these other modules and libraries:

=over

=item *

JSON

=item *

Net::NTP

=item *

Lazy::Utils

=back

=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/Zabbix-Check>

B<CPAN> L<https://metacpan.org/release/Zabbix-Check>

=head1 AUTHOR

Orkun Karaduman (ORKUN) <orkun@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman <orkunkaraduman@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
