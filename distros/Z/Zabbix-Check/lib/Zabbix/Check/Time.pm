package Zabbix::Check::Time;
=head1 NAME

Zabbix::Check::Systemd - Zabbix check for system time

=head1 VERSION

version 1.10

=head1 SYNOPSIS

Zabbix check for system time

	UserParameter=cpan.zabbix.check.time.epoch,/usr/bin/perl -MZabbix::Check::Time -e_epoch
	UserParameter=cpan.zabbix.check.time.zone,/usr/bin/perl -MZabbix::Check::Time -e_zone
	UserParameter=cpan.zabbix.check.time.ntp_offset[*],/usr/bin/perl -MZabbix::Check::Time -e_ntp_offset -- $1 $2

=head3 epoch

gets system time epoch in seconds

=head3 zone

gets system time zone, eg: +0200

=head3 ntp_offset $1 $2

gets system time difference by NTP server

$1: I<server, by defaut pool.ntp.org>

$2: I<port, by default 123>

=cut
use strict;
use warnings;
no warnings qw(qw utf8);
use v5.14;
use utf8;
use POSIX;
use Net::NTP;
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
	our @EXPORT      = qw(_epoch _zone _ntp_offset);
	# Functions and variables which can be optionally exported
	our @EXPORT_OK   = qw();
}


sub _epoch
{
	my $result = time();
	print $result;
	return $result;
}

sub _zone
{
	my $result = strftime("%z", gmtime());
	print $result;
	return $result;
}

sub _ntp_offset
{
	my ($server, $port) = map(zbxDecode($_), @ARGV);
	$server = "pool.ntp.org" unless $server;
	my $result = "";
	my %ntp;
	for (1..5)
	{
		eval { %ntp = get_ntp_response($server, $port) };
		$result = sprintf("%.3f", $ntp{Offset}) if defined $ntp{Offset};
		last unless $result eq "";
		sleep(1);
	}
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
