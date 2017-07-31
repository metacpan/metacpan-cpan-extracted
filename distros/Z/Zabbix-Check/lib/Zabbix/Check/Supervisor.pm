package Zabbix::Check::Supervisor;
=head1 NAME

Zabbix::Check::Supervisor - Zabbix check for Supervisor service

=head1 VERSION

version 1.11

=head1 SYNOPSIS

Zabbix check for Supervisor service

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
	our @EXPORT      = qw(_installed _running _worker_discovery _worker_status);
	our @EXPORT_OK   = qw();
}


our ($supervisorctl) = whereis('supervisorctl');
our ($supervisord) = whereis('supervisord');
our ($python) = whereis('python');


sub get_statuses
{
	return unless $supervisorctl;
	my $result = file_cache("all", 30, sub
	{
		my $result = {};
		for (`$supervisorctl status 2>/dev/null`)
		{
			chomp;
			my ($name, $status) = /^(\S+)\s+(\S+)\s*/;
			$result->{$name} = $status;
		}
		return $result;
	});
	return $result;
}

sub _installed
{
	my $result = $supervisorctl? 1: 0;
	print $result;
	return $result;
}

sub _running
{
	my $result = 2;
	if ($supervisorctl)
	{
		system "pgrep -f '$python $supervisord' >/dev/null 2>&1";
		$result = ($? == 0)? 1: 0;
	}
	print $result;
	return $result;
}

sub _worker_discovery
{
	my @items;
	my $statuses = get_statuses();
	@items = map({ name => $_}, keys %$statuses) if $statuses;
	return print_discovery(@items);
}

sub _worker_status
{
	my ($name) = map(zbx_decode($_), @ARGV);
	return "" unless $name;
	my $result = "";
	my $statuses = get_statuses();
	$result = $statuses->{$name} if defined($statuses->{$name});
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
