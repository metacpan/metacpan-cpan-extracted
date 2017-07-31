package Zabbix::Check::Disk;
=head1 NAME

Zabbix::Check::Disk - Zabbix check for disk

=head1 VERSION

version 1.11

=head1 SYNOPSIS

Zabbix check for disk

=cut
use strict;
use warnings;
use v5.10.1;
use JSON;
use Lazy::Utils;

use Zabbix::Check;


BEGIN
{
	require Exporter;
	our $VERSION     = '1.11';
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(_discovery _bps _iops _ioutil);
	our @EXPORT_OK   = qw();
}


sub disks
{
	my $result = {};
	for my $blockpath (glob("/sys/dev/block/*"))
	{
		my $uevent = file_get_contents("$blockpath/uevent");
		next unless defined($uevent);
		my ($major) = $uevent =~ /^\QMAJOR=\E(.*)/m;
		my ($minor) = $uevent =~ /^\QMINOR=\E(.*)/m;
		my ($devname) = $uevent =~ /^\QDEVNAME=\E(.*)/m;
		my ($devtype) = $uevent =~ /^\QDEVTYPE=\E(.*)/m;
		my $devpath = "/dev/$devname";
		my $disk = {
			blockpath => $blockpath,
			devname => $devname,
			devtype => $devtype,
			devpath => $devpath,
			major => $major,
			minor => $minor,
			size => defined($_ = file_get_contents("$blockpath/size"))? trim($_)*512: undef,
			removable => defined($_ = file_get_contents("$blockpath/removable"))? trim($_): undef,
			partition => defined($_ = file_get_contents("$blockpath/partition"))? trim($_): undef,
			dmname => undef,
			dmpath => undef,
		};
		if (defined(my $dmname = file_get_contents("$blockpath/dm/name")))
		{
			$dmname = trim($dmname);
			$disk->{dmname} = $dmname;
			$disk->{dmpath} = "/dev/mapper/$dmname";
		}
		my $dmpath = defined($disk->{dmpath})? $disk->{dmpath}: "";
		for my $mount (grep(/^(\Q$disk->{devpath}\E|\Q$dmpath\E)\s+/, defined($_ = file_get_contents("/proc/mounts"))? split("\n", $_): ()))
		{
			$mount = trim($mount);
			my ($mountname, $mountpoint, $fstype) = $mount =~ /^(\S+)\s+(\S+)\s+(\S+)\s+/;
			next unless $mountname =~ /^\Q$disk->{devpath}\E|\Q$dmpath\E$/;
			$disk->{mountpoint} = $mountpoint;
			$disk->{fstype} = $fstype;
		}
		$result->{$devname} = $disk;
	}
	return $result;
}

sub stats
{
	my $result = {};
	my $disks = disks();
	for my $devname (keys %$disks)
	{
		my $disk = $disks->{$devname};
		my $stat_line = defined($_ = file_get_contents("$disk->{blockpath}/stat"))? trim($_): "";
		next unless $stat_line;
		my $stat = { 'epoch' => time() };
		(
			$stat->{readIOs},
			$stat->{readsMerges},
			$stat->{readSectors},
			$stat->{readWaits},
			$stat->{writeIOs},
			$stat->{writesMerges},
			$stat->{writeSectors},
			$stat->{writeWaits},
			$stat->{inFlight},
			$stat->{IOTicks},
			$stat->{totalWaits},
		) = $stat_line =~ /^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/;
		$result->{$devname} = $stat;
	}
	return $result;
}

sub analyze_stats
{
	my $now = time();
	my $stats;
	my $old_stats;
	my $tmp_prefix = (caller(0))[3];
	$tmp_prefix =~ s/\Q::\E/-/g;
	$tmp_prefix = "/tmp/".$tmp_prefix.".";
	for my $tmp_path (sort {$b cmp $a} glob("$tmp_prefix*"))
	{
		if (my ($epoch, $pid) = $tmp_path =~ /^\Q$tmp_prefix\E(\d*)\.(\d*)/)
		{
			if ($now-$epoch < 1*60)
			{
				if (not $stats)
				{
					my $tmp = file_get_contents($tmp_path);
					eval { $stats = from_json($tmp) } if $tmp;
				}
				next;
			}
			if (not $old_stats)
			{
				my $tmp = file_get_contents($tmp_path);
				eval { $old_stats = from_json($tmp) } if $tmp;
				next unless not $tmp or $@;
			}
			next unless $now-$epoch > 2*60;
		}
		unlink($tmp_path);
	}
	unless ($stats)
	{
		$stats = stats();
		my $tmp;
		eval { $tmp = to_json($stats, {pretty => 1}) };
		file_put_contents("$tmp_prefix$now.$$", $tmp) if $tmp;
	}
	return unless $old_stats;
	my $result = {};
	for my $devname (keys %$stats)
	{
		my $stat = $stats->{$devname};
		my $old_stat = $old_stats->{$devname};
		next unless defined $old_stat;
		my $diff = $stat->{epoch} - $old_stat->{epoch};
		next unless $diff;
		$result->{$devname} = {};

		my $sector;
		my $io;

		$sector = $stat->{readSectors} - $old_stat->{readSectors};
		$io = $stat->{readIOs} - $old_stat->{readIOs};
		$result->{$devname}->{bps_read} = 512*$sector/$diff;
		$result->{$devname}->{iops_read} = $io/$diff;

		$sector = $stat->{writeSectors} - $old_stat->{writeSectors};
		$io = $stat->{writeIOs} - $old_stat->{writeIOs};
		$result->{$devname}->{bps_write} = 512*$sector/$diff;
		$result->{$devname}->{iops_write} = $io/$diff;

		$sector = $stat->{readSectors} - $old_stat->{readSectors} + $stat->{writeSectors} - $old_stat->{writeSectors};
		$io = $stat->{readIOs} - $old_stat->{readIOs} + $stat->{writeIOs} - $old_stat->{writeIOs};
		$result->{$devname}->{bps_total} = 512*$sector/$diff;
		$result->{$devname}->{iops_total} = $io/$diff;

		$result->{$devname}->{ioutil} = 100*($stat->{IOTicks} - $old_stat->{IOTicks})/(1000*$diff);
	}
	return $result;
}

sub _discovery
{
	my ($removable) = @_;
	my @items;
	my $disks = disks();
	for my $devname (keys %$disks)
	{
		my $disk = $disks->{$devname};
		next if $devname =~/^loop\d*$/i or $devname =~ /^ram\d*$/i;
		next if not $removable and $disk->{removable};
		push @items, $disk;
	}
	return print_discovery(@items);
}

sub _bps
{
	my ($devname, $type) = map(zbx_decode($_), @ARGV);
	return "" unless defined($devname) and $type and $type =~ /^read|write|total$/;
	my $result = 0;
	my $analyzed = analyze_stats();
	my $status = $analyzed->{$devname} if $analyzed;
	$result = sprintf("%.2f", $status->{"bps_$type"}) if $status;
	print $result;
	return $result;
}

sub _iops
{
	my ($devname, $type) = map(zbx_decode($_), @ARGV);
	return "" unless defined($devname) and $type and $type =~ /^read|write|total$/;
	my $result = 0;
	my $analyzed = analyze_stats();
	my $status = $analyzed->{$devname} if $analyzed;
	$result = sprintf("%.2f", $status->{"iops_$type"}) if $status;
	print $result;
	return $result;
}

sub _ioutil
{
	my ($devname) = map(zbx_decode($_), @ARGV);
	return "" unless defined($devname);
	my $result = 0;
	my $analyzed = analyze_stats();
	my $status = $analyzed->{$devname} if $analyzed;
	$result = sprintf("%.2f", $status->{"ioutil"}) if $status;
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
