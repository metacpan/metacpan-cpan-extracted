package Zabbix::Check::Redis;
=head1 NAME

Zabbix::Check::Redis - Zabbix check for Redis service

=head1 VERSION

version 1.12

=head1 SYNOPSIS

Zabbix check for Redis service

=cut
use strict;
use warnings;
use v5.10.1;
use Time::HiRes;
use Lazy::Utils;

use Zabbix::Check;


BEGIN
{
	require Exporter;
	our $VERSION     = '1.12';
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(_installed _discovery _running _info _resptime);
	our @EXPORT_OK   = qw();
}


our ($redis_server) = whereis('redis-server');
our ($redis_cli) = whereis('redis-cli');


sub bind_to_redis_cli_args
{
	my ($bind) = @_;
	return "" unless defined($bind);
	if ($bind =~ /^([^:]*):(\d*)$/)
	{
		my ($host, $port);
		$host = "127.0.0.1";
		$host = shellmeta($1, 1) if $1 ne "";
		$port = "6379";
		$port = shellmeta($2, 1) if $2 ne "";
		return "-h $host -p $port";
	}
	$bind = shellmeta($bind, 1);
	return "-s $bind";
}

sub get_info
{
	return unless $redis_cli;
	my ($bind) = @_;
	my $redis_cli_args = bind_to_redis_cli_args($bind);
	my $result = file_cache("all", 30, sub
	{
		my $result = { 'epoch' => time() };
		my $topic;
		for (`$redis_cli $redis_cli_args info 2>/dev/null`)
		{
			chomp;
			if (/^#(.*)/)
			{
				$topic = trim($1);
				next;
			}
			my ($key, $val) = split(":", $_, 2);
			next unless defined($topic) and defined($key) and defined($val);
			$key = "$topic:".trim($key);
			$val = trim($val);
			$result->{$key} = $val;
		}
		return $result;
	});
	return $result;
}

sub _installed
{
	my $result = $redis_server? 1: 0;
	print $result;
	return $result;
}

sub _discovery
{
	my @items;
	for (`ps -C redis-server -o pid,cmd 2>/dev/null`)
	{
		chomp;
		if (/^\s*(\d*)\s+\Q$redis_server\E\ (\S+)/)
		{
			push @items, { bind => $2 };
		}
	}
	return print_discovery(@items);
}

sub _running
{
	my ($bind) = @_;
	my $result = 2;
	if ($redis_server)
	{
		my $cmd = $redis_server;
		$cmd .= " $bind" if defined($bind);
		$cmd = shellmeta($cmd);
		system "pgrep -f \"$cmd\" >/dev/null 2>&1";
		$result = ($? == 0)? 1: 0;
	}
	print $result;
	return $result;
}

sub _info
{
	my ($key, $bind) = map(zbx_decode($_), @ARGV);
	return "" unless $key;
	my $result = "";
	my $info = get_info($bind);
	$result = $info->{$key} if defined($info->{$key});
	print $result;
	return $result;
}

sub _resptime
{
	my ($bind) = map(zbx_decode($_), @ARGV);
	my $key = (caller(0))[3];
	$key =~ s/\Q::\E/-/g;
	$key = shellmeta($key, 1);
	my $redis_cli_args = bind_to_redis_cli_args($bind);
	my $time = Time::HiRes::time();
	`$redis_cli $redis_cli_args GET $key 2>/dev/null`;
	my $result = Time::HiRes::time()-$time;
	`$redis_cli $redis_cli_args INCR $key 2>/dev/null`;
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
