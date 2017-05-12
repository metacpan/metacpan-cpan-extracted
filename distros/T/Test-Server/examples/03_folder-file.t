#!/usr/bin/perl

=head1 NAME

folder-file.t - check sizes and permittions

=head SYNOPSIS

	cat >> test-server.yaml << __YAML_END__
	folder-file:
	    /var/log/apache2:
	        user: root
	        group: root
	        max-size: 500M
	        perm: 755
	        recurse: 1
	    /var/tmp:
	        max-size: 250M
        /tmp/non-existing:
	    /tmp/test-file:
	        perm: 2775
	        max-size: 250M
	__YAML_END__

=cut

use strict;
use warnings;

use Test::More;
use Test::Differences;
use YAML::Syck 'LoadFile';
use FindBin '$Bin';
use Test::Server::Util qw(parse_size format_size);

my $STAT_PERM = 2;
my $STAT_UID  = 4;
my $STAT_GID  = 5;

eval "use Filesys::DiskUsage qw/du/;";
plan 'skip_all' => "need Filesys::DiskUsage to run web tests" if $@;

my $config = LoadFile($Bin.'/test-server.yaml');

plan 'skip_all' => "no configuration sections for 'folder-file' "
	if (
		not $config
		or not $config->{'folder-file'}
	);
$config = $config->{'folder-file'};


exit main();

sub main {
	my %file_with_name = %{$config};
	my $tests = keys %file_with_name;

	plan 'skip_all' => 'no tests defined'
		if not $tests;
	plan 'no_plan';
	
	foreach my $filename (keys %file_with_name) {
		my %file_checks = %{$file_with_name{$filename} || {}};
		
		SKIP: {
			# check if readable for us
			ok(-r $filename, 'is folder '.$filename.' readable')
				or skip 'skipping '.$filename.', not readable', 1;
			
			# check size
			my $size = $file_checks{'max-size'};
			if (defined $size) {
				my $du_size = du($filename);
				cmp_ok($du_size, '<', parse_size($size), 'check '.$filename.' size < '.$size)
					or diag($filename.' has '.format_size($du_size));
			}
			
			my @file_stat = stat($filename);
			
			# get uid
			my $uid;
			my $user = $file_checks{'user'};
			if ($user) {
			    $uid = $user;
    			$uid = getpwnam($user)
    				if $user !~ m{^\s*\d+\s*$};
    			$uid = $user
    			    if not defined $uid;
    		}
			
			# get gid
			my $gid;
			my $group = $file_checks{'group'};
			if ($group) {
			    $gid = $group;
    			$gid = getgrnam($group)
    				if $group !~ m{^\s*\d+\s*$};
    			$gid = $group
    			    if not defined $gid;
    		}
			
			# check recursively
			eq_or_diff(
				[ check_recursively($filename, $file_checks{'recurse'}, $uid, $gid, $file_checks{'perm'}) ],
				[],
				'check uid,gid,permissions on '.$filename,
			);
		}
	}	
		
	return 0;
}

sub check_recursively {
	my ($filename, $recurse, $uid, $gid, $perm) = @_;
	
	return
		if ((not $filename) or (not -d $filename));
	
	my @bad_files;
	my @files_to_check = ($filename);
	
	while (my $filename = pop @files_to_check) {
		my @stat = stat($filename);
		
		my $file_uid  = $stat[$STAT_UID];
		my $file_gid  = $stat[$STAT_GID];
		my $file_perm = sprintf '%lo', $stat[$STAT_PERM] & 07777;
		
		push @bad_files, 'bad uid for '.$filename.': '.$file_uid.' does not match '.$uid
			if ((defined $uid) and ($file_uid ne $uid));
		push @bad_files, 'bad gid for '.$filename.': '.$file_gid.' does not match '.$gid
			if ((defined $gid) and ($file_gid ne $gid));
		push @bad_files, 'bad permissions for '.$filename.': '.$file_perm.' does not match '.$perm
			if ((defined $perm) and ($file_perm ne $perm));

		if ($recurse and (-d $filename)) {
			opendir(my $dir_handle, $filename) || return;
			while (my $filename_to_check = readdir($dir_handle)) {
				next if $filename_to_check eq '.';
				next if $filename_to_check eq '..';
				push @files_to_check, File::Spec->catfile($filename, $filename_to_check);
			}
			closedir($dir_handle);
		}
	}
	
	return @bad_files;
}



__END__

=head1 TODO

recursive

=head1 AUTHOR

Jozef Kutej

for the idea thanks to Peter Hartl

=cut
