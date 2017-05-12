package Zabbix::Check::RabbitMQ;
=head1 NAME

Zabbix::Check::RabbitMQ - Zabbix check for RabbitMQ service

=head1 VERSION

version 1.10

=head1 SYNOPSIS

Zabbix check for RabbitMQ service

	UserParameter=cpan.zabbix.check.rabbitmq.installed,/usr/bin/perl -MZabbix::Check::RabbitMQ -e_installed
	UserParameter=cpan.zabbix.check.rabbitmq.running,/usr/bin/perl -MZabbix::Check::RabbitMQ -e_running
	UserParameter=cpan.zabbix.check.rabbitmq.vhost_discovery[*],/usr/bin/perl -MZabbix::Check::RabbitMQ -e_vhost_discovery -- $1
	UserParameter=cpan.zabbix.check.rabbitmq.queue_discovery[*],/usr/bin/perl -MZabbix::Check::RabbitMQ -e_queue_discovery -- $1
	UserParameter=cpan.zabbix.check.rabbitmq.queue_status[*],/usr/bin/perl -MZabbix::Check::RabbitMQ -e_queue_status -- $1 $2 $3

=head3 installed

checks RabbitMQ is installed: 0 | 1

=head3 running

checks RabbitMQ is installed and running: 0 | 1 | 2 = not installed

=head3 vhost_discovery $1

discovers RabbitMQ vhosts

$1: I<cache expiry in seconds, by default 0>

=head3 queue_discovery $1

discovers RabbitMQ queues

$1: I<cache expiry in seconds, by default 0>

=head3 queue_status $1 $2 $3

gets RabbitMQ queue status using queue discovery cache

$1: I<vhost name>

$2: I<queue name>

$3: I<type: ready|unacked|total>

=cut
use strict;
use warnings;
no warnings qw(qw utf8);
use v5.14;
use utf8;
use Lazy::Utils;

use Zabbix::Check;


BEGIN
{
	require Exporter;
	# set the version for version checking
	our $VERSION     = '1.10';
	# Inherit from Exporter to export functions and variables
	our @ISA         = qw(Exporter);
	# Functions and variables which are exported by default
	our @EXPORT      = qw(_installed _running _vhost_discovery _queue_discovery _queue_status);
	# Functions and variables which can be optionally exported
	our @EXPORT_OK   = qw();
}


our ($rabbitmqctl) = whereisBin('rabbitmqctl');


sub getVhosts
{
	return unless $rabbitmqctl;
	my ($expiry) = @_;
	$expiry = -1 unless defined($expiry);
	my $result = fileCache("all", $expiry, sub
	{
		my $result = {};
		my $first = 1;
		for my $line (`$rabbitmqctl list_vhosts 2>/dev/null`)
		{
			chomp $line;
			if ($first)
			{
				$first = 0;
				next;
			}
			my ($name) = $line =~ /^(.*)/;
			$result->{$name} = { 'name' => $name };
		}
		return $result;
	});
	return $result;
}

sub getQueues
{
	return unless $rabbitmqctl;
	my ($vhost, $expiry) = @_;
	my $vhostS = shellmeta($vhost);
	$expiry = -1 unless defined($expiry);
	my $result = fileCache($vhost, $expiry, sub
	{
		my $result = {};
		my $first = 1;
		for my $line (`$rabbitmqctl list_queues -p \"$vhostS\" name messages_ready messages_unacknowledged messages 2>/dev/null`)
		{
			chomp $line;
			if ($first)
			{
				$first = 0;
				next;
			}
			my ($name, $ready, $unacked, $total) = $line =~ m/^([^\t]+)\t+([^\t]+)\t+([^\t]+)\t+([^\t]+)\t*/;
			$result->{$name} = {'ready' => $ready, 'unacked' => $unacked, 'total' => $total};
		}
		return $result;
	});
	return $result;
}

sub _installed
{
	my $result = $rabbitmqctl? 1: 0;
	print $result;
	return $result;
}

sub _running
{
	my $result = 2;
	if ($rabbitmqctl)
	{
		system "$rabbitmqctl cluster_status >/dev/null 2>&1";
		$result = ($? == 0)? 1: 0;
	}
	print $result;
	return $result;
}

sub _vhost_discovery
{
	my ($expiry) = map(zbxDecode($_), @ARGV);
	$expiry = 0 unless defined($expiry);
	my @items;
	my $vhosts = getVhosts($expiry);
	$vhosts = {} unless $vhosts;
	for my $vhost (keys %$vhosts)
	{ 
		push @items, { vhost => $vhost };
	}
	return printDiscovery(@items);
}

sub _queue_discovery
{
	my ($expiry) = map(zbxDecode($_), @ARGV);
	$expiry = 0 unless defined($expiry);
	my @items;
	my $vhosts = getVhosts($expiry);
	$vhosts = {} unless $vhosts;
	for my $vhost (keys %$vhosts)
	{ 
		my $queues = getQueues($vhost, $expiry);
		$queues = {} unless $queues;
		for my $queue (keys %$queues)
		{
			push @items, { vhost => $vhost, queue => $queue };
		}
	}
	return printDiscovery(@items);
}

sub _queue_status
{
	my ($vhost, $queue, $type) = map(zbxDecode($_), @ARGV);
	return unless $vhost and $queue and $type and $type =~ /^ready|unacked|total$/;
	my $result = "";
	my $queues = getQueues($vhost);
	$result = $queues->{$queue}->{$type} if defined($queues->{$queue}->{$type});
	print $result;
	return $result;	
}


1;
__END__
=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/Zabbix-Check>

B<CPAN> L<https://metacpan.org/release/Zabbix-Check>

=head1 AUTHOR

Orkun Karaduman <orkunkaraduman@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016  Orkun Karaduman <orkunkaraduman@gmail.com>

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
