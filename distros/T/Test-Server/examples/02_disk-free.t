#!/usr/bin/perl

=head1 NAME

disk-free - check disk free space and free inodes

=head2 SYNOPSIS

	cat >> test-server.yaml << __YAML_END__	
	disk-free:
	    /:
	        max-used: 95%
	        max-inodes: 90%
	    /var:
	        max-df: 1G
	        max-inodes: 64875
	__YAML_END__	


=cut

use strict;
use warnings;

use Test::More;
use Test::Differences;

use FindBin '$Bin';
use YAML::Syck 'LoadFile';
use Test::Server::Util qw(parse_size format_size);

eval "use Filesys::DiskSpace";
plan 'skip_all' => "need Filesys::DiskSpace to run disk free tests" if $@;

my $config = LoadFile($Bin.'/test-server.yaml');

# by default check root filesystem
$config->{'disk-free'} = { '/' => undef }
	if not $config->{'disk-free'};

$config = $config->{'disk-free'};

exit main();

sub main {
	plan 'tests' => scalar(keys %$config)*2;
	
	foreach my $dir (keys %$config) {
		my $max_used   = $config->{$dir}->{'max-used'}   || '95%';
		my $max_inodes = $config->{$dir}->{'max-inodes'} || '90%';
		
		my ($fs_type, $fs_desc, $used_space, $avail_space, $used_inodes, $avail_inodes)
			= Filesys::DiskSpace::df($dir);

		my $current_used;
		my $diff_used;
		
		# check used disk space
		if ($max_used =~ m/^(.+)%\s*$/) {
			$max_used = $1;
			$current_used = int($used_space*100/($avail_space+$used_space));
			$diff_used    = ($current_used - $max_used).'%';
		}
		else {
			$max_used = parse_size($max_used);
			$current_used = $used_space * 1024;
			$diff_used    = format_size($current_used - $max_used);
		}
		
		cmp_ok($current_used, '<=', $max_used, 'check disk space on '.$dir)
			or diag('difference is ', $diff_used);

		# check used inodes
		if ($max_inodes =~ m/^(.+)%\s*$/) {
			$max_inodes   = $1;
			$current_used = int($used_inodes*100/($avail_inodes+$used_inodes));
			$diff_used    = ($current_used - $max_inodes).'%';
		}
		else {
			$max_inodes = parse_size($max_inodes);
			$current_used = $used_inodes;
			$diff_used    = $current_used - $max_inodes;
		}
		
		cmp_ok($current_used, '<=', $max_inodes, 'check inodes on '.$dir)
			or diag('difference is ', $diff_used);
	}
	
	return 0;
}


__END__

=head1 NOTE

Disk Free checking depends on L<Filesys::DiskSpace>.

=head1 AUTHOR

Jozef Kutej

=cut
