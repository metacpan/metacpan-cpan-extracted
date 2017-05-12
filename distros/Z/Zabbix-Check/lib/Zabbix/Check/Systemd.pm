package Zabbix::Check::Systemd;
=head1 NAME

Zabbix::Check::Systemd - Zabbix check for Systemd services

=head1 VERSION

version 1.10

=head1 SYNOPSIS

Zabbix check for Systemd services

	UserParameter=cpan.zabbix.check.systemd.installed,/usr/bin/perl -MZabbix::Check::Systemd -e_installed
	UserParameter=cpan.zabbix.check.systemd.system_status,/usr/bin/perl -MZabbix::Check::Systemd -e_system_status
	UserParameter=cpan.zabbix.check.systemd.service_discovery[*],/usr/bin/perl -MZabbix::Check::Systemd -e_service_discovery -- $1
	UserParameter=cpan.zabbix.check.systemd.service_status[*],/usr/bin/perl -MZabbix::Check::Systemd -e_service_status -- $1

=head3 installed

checks Systemd is installed: 0 | 1

=head3 system_status

gets Systemd system status: initializing | starting | running | degraded | maintenance | stopping | offline | unknown

=head3 service_discovery

discovers Systemd enabled services

$1: I<regex of service name, by default undefined>

=head3 service_status $1

gets Systemd enabled service status: active | inactive | failed | unknown | ...

$1: I<service name>

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
	our @EXPORT      = qw(_installed _system_status _service_discovery _service_status);
	# Functions and variables which can be optionally exported
	our @EXPORT_OK   = qw();
}


our ($systemctl) = whereisBin('systemctl');


sub getUnitFiles
{
	return unless $systemctl;
	my ($type) = @_;
	my $result = {};
	for (`$systemctl --no-legend list-unit-files 2>/dev/null`)
	{
		chomp;
		last unless s/^\s+|\s+$//gr;
		my ($unit, $state) = /^(\S+)\s+(\S+)/;
		my $info = {
			unit => $unit,
			state => $state,
		};
		($info->{name}, $info->{type}) = $unit =~ /^([^\.]*)\.(.*)/;
		$result->{$unit} = $info if not $type or $type eq $info->{type};
	}
	return $result;
}

sub getUnits
{
	return unless $systemctl;
	my ($type) = @_;
	my $result = {};
	my $first = 1;
	for (`$systemctl --no-legend -a list-units 2>/dev/null`)
	{
		chomp;
		last unless s/^\s+|\s+$//gr;
		my ($unit, $load, $active, $sub, $desc) = /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)/;
		my $info = {
			unit => $unit,
			load => $load,
			active => $active,
			sub => $sub,
			desc => $desc,
		};
		($info->{name}, $info->{type}) = $unit =~ /^([^\.]*)\.(.*)/;
		$result->{$unit} = $info if not $type or $type eq $info->{type};
	}
	return $result;
}

sub _installed
{
	my $result = $systemctl? 1: 0;
	print $result;
	return $result;
}

sub _system_status
{
	my $result = "";
	my $line = `$systemctl is-system-running 2>/dev/null` if $systemctl;
	if ($line)
	{
		chomp $line;
		$result = $line;
	}
	print $result;
	return $result;
}

sub _service_discovery
{
	my ($nameRgx) = map(zbxDecode($_), @ARGV);
	my @items;
	my $units = getUnits('service');
	@items = map($units->{$_}, grep({ not defined($nameRgx) or $units->{$_}->{name} =~ /$nameRgx/ } keys %$units)) if $units;
	return printDiscovery(@items);
}

sub _service_status
{
	my ($name) = map(zbxDecode($_), @ARGV);
	return unless $name;
	my $nameS = shellmeta($name);
	my $result = "";
	my $line = `$systemctl is-active \"$nameS.service\" 2>/dev/null` if $systemctl;
	if ($line)
	{
		chomp $line;
		$result = $line;
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
