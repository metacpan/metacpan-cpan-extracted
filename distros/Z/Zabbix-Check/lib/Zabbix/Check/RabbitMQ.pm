package Zabbix::Check::RabbitMQ;
=head1 NAME

Zabbix::Check::RabbitMQ - Zabbix check for RabbitMQ service

=head1 VERSION

version 1.11

=head1 SYNOPSIS

Zabbix check for RabbitMQ service

=cut
use strict;
use warnings;
use v5.10.1;
use Lazy::Utils;

use Zabbix::Check;


BEGIN
{
	require Exporter;
	our $VERSION     = '1.11';
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(_installed _running _vhost_discovery _queue_discovery _queue_status);
	our @EXPORT_OK   = qw();
}


our ($rabbitmqctl) = whereis('rabbitmqctl');


sub get_vhosts
{
	return unless $rabbitmqctl;
	my ($expiry) = @_;
	my $result = file_cache("all", $expiry, sub
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

sub get_queues
{
	return unless $rabbitmqctl;
	my ($vhost, $expiry) = @_;
	my $vhost_s = shellmeta($vhost);
	my $result = file_cache($vhost, $expiry, sub
	{
		my $result = {};
		my $first = 1;
		for my $line (`$rabbitmqctl list_queues -p \"$vhost_s\" name messages_ready messages_unacknowledged messages 2>/dev/null`)
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
	my ($expiry) = map(zbx_decode($_), @ARGV);
	$expiry = 0 unless defined($expiry);
	my @items;
	my $vhosts = get_vhosts($expiry);
	$vhosts = {} unless $vhosts;
	for my $vhost (keys %$vhosts)
	{
		push @items, { vhost => $vhost };
	}
	return print_discovery(@items);
}

sub _queue_discovery
{
	my ($expiry) = map(zbx_decode($_), @ARGV);
	$expiry = 0 unless defined($expiry);
	my @items;
	my $vhosts = get_vhosts($expiry);
	$vhosts = {} unless $vhosts;
	for my $vhost (keys %$vhosts)
	{
		my $queues = get_queues($vhost, $expiry);
		$queues = {} unless $queues;
		for my $queue (keys %$queues)
		{
			push @items, { vhost => $vhost, queue => $queue };
		}
	}
	return print_discovery(@items);
}

sub _queue_status
{
	my ($vhost, $queue, $type) = map(zbx_decode($_), @ARGV);
	return "" unless $vhost and $queue and $type and $type =~ /^ready|unacked|total$/;
	my $result = "";
	my $queues = get_queues($vhost);
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
