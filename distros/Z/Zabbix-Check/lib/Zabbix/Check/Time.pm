package Zabbix::Check::Time;
=head1 NAME

Zabbix::Check::Systemd - Zabbix check for system time

=head1 VERSION

version 1.11

=head1 SYNOPSIS

Zabbix check for system time

=cut
use strict;
use warnings;
use v5.10.1;
use POSIX;
use Net::NTP;
use Lazy::Utils;

use Zabbix::Check;


BEGIN
{
	require Exporter;
	our $VERSION     = '1.11';
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(_epoch _zone _ntp_offset);
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
	my ($server, $port) = map(zbx_decode($_), @ARGV);
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
