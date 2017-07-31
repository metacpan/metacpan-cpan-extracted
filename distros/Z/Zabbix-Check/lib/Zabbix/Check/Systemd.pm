package Zabbix::Check::Systemd;
=head1 NAME

Zabbix::Check::Systemd - Zabbix check for Systemd services

=head1 VERSION

version 1.11

=head1 SYNOPSIS

Zabbix check for Systemd services

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
	our @EXPORT      = qw(_installed _system_status _service_discovery _service_status);
	our @EXPORT_OK   = qw();
}


our ($systemctl) = whereis('systemctl');


sub get_unit_files
{
	return unless $systemctl;
	my ($type) = @_;
	my $result = {};
	for (`$systemctl --no-legend list-unit-files 2>/dev/null`)
	{
		$_ = trim($_);
		last unless $_;
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

sub get_units
{
	return unless $systemctl;
	my ($type) = @_;
	my $result = {};
	my $first = 1;
	for (`$systemctl --no-legend -a list-units 2>/dev/null`)
	{
		$_ = trim($_);
		last unless $_;
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
	my ($name_rgx) = map(zbx_decode($_), @ARGV);
	my @items;
	my $units = get_units('service');
	@items = map($units->{$_}, grep({ not defined($name_rgx) or $units->{$_}->{name} =~ /$name_rgx/ } keys %$units)) if $units;
	return print_discovery(@items);
}

sub _service_status
{
	my ($name) = map(zbx_decode($_), @ARGV);
	return "" unless $name;
	my $name_s = shellmeta($name);
	my $result = "";
	my $line = `$systemctl is-active \"$name_s.service\" 2>/dev/null` if $systemctl;
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
