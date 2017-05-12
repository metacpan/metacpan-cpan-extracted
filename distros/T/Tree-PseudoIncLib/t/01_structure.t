#!perl -w
use strict;

# Check and Make Dynamic Test Structure
# =====================================
use Log::Log4perl;
use Fcntl ':mode';
use Cwd;
use Test::Simple tests => 10;

Log::Log4perl::init( 'data/log.config' );

# 01: data/testlibs/ should always exist and contain only:
#        lib1
#        lib2
#        lib3
	my $base_lib_path = 'data/testlibs/';
	my @lib_list = `ls $base_lib_path`;
	my $message = join("\t\t",@lib_list);
	my $nn = @lib_list;
	my $good = $nn eq 3;
	$good = $lib_list[0] =~ /^lib1/ if $good;
	$good = $lib_list[1] =~ /^lib2/ if $good;
	$good = $lib_list[2] =~ /^lib3/ if $good;
	print STDERR "\n\tList of the Libraries in $base_lib_path has $nn items:\n\t$message" unless $good;
ok($good, 'first level is ok');

# 02: check if we have symlink in lib1:
	$base_lib_path = 'data/testlibs/lib1/';
	my $base_dir  = cwd;    # to use for relational paths
	my $full_file_name = $base_dir.'/'.$base_lib_path.'file_4.htm';
	unless ( -e $full_file_name ) {
	#	print STDERR "\n\tItem $full_file_name did not exist\n";
		# create symlink:
		chdir $base_lib_path;
		`ln -s file_3.txt file_4.htm`;
		chdir $base_dir; # back to business
	}
	my $mode = (stat($full_file_name))[2];
	print STDERR "\n\tItem $full_file_name is not a symlink\n" unless $mode & S_IFLNK;
ok($mode & S_IFLNK, 'symlink is ok');

# 03: check if we have empty directory in lib1:
	$full_file_name = $base_dir.'/'.$base_lib_path.'thisisempty';
	unless ( -e $full_file_name ) {
	#	print STDERR "\n\tItem $full_file_name did not exist\n";
		# create it:
		chdir $base_lib_path;
		`mkdir thisisempty`;
		chdir $base_dir; # back to business
	}
	$mode = (stat($full_file_name))[2];
	print STDERR "\n\tItem $full_file_name is not a directory\n" unless $mode & S_IFDIR;
ok($mode & S_IFDIR, 'empty directory is ok');

# 04: test structure of lib1; should be like:
#
# -rw-r--r--    1 slava    root           18 Aug 29 04:57 file_1.pm
# -rw-r--r--    1 slava    root           18 Aug 29 04:57 file_2.html
# -rw-r--r--    1 slava    root           18 Aug 29 04:57 file_3.txt
# lrwxrwxrwx    1 slava    root           10 Aug 29 04:57 file_4.htm -> file_3.txt
# drwxr-xr-x    2 slava    root         4096 Aug 29 04:57 thisisempty

	@lib_list = `ls $base_lib_path`;
	my @lib_list_full = `ls -l $base_lib_path`;
	$nn = @lib_list;
	$message = join("\t\t",@lib_list_full);
	$good = $nn eq 5;
	$good = $lib_list[0] =~ /^file_1\.pm/ if $good;
	$good = $lib_list[1] =~ /^file_2\.html/ if $good;
	$good = $lib_list[2] =~ /^file_3\.txt/ if $good;
	$good = $lib_list[3] =~ /^file_4\.htm/ if $good;
	$good = $lib_list[4] =~ /^thisisempty/ if $good;
	print STDERR "\n\tList of items in $base_lib_path has $nn items:\n\t$message" unless $good;
ok($good, 'lib1 is ok');

# 05: check if we have symlink in lib2:
	$base_lib_path = 'data/testlibs/lib2/';
	$base_dir  = cwd;    # to use for relational paths
	$full_file_name = $base_dir.'/'.$base_lib_path.'file_4.htm';
	unless ( -e $full_file_name ) {
	#	print STDERR "\n\tItem $full_file_name did not exist\n";
		# create symlink:
		chdir $base_lib_path;
		`ln -s file_3.txt file_4.htm`;
		chdir $base_dir; # back to business
	}
	$mode = (stat($full_file_name))[2];
	print STDERR "\n\tItem $full_file_name is not a symlink\n" unless $mode & S_IFLNK;
ok($mode & S_IFLNK, 'symlink is ok');

# 06: check if we have empty directory in lib2:
	$full_file_name = $base_dir.'/'.$base_lib_path.'thisisempty';
	unless ( -e $full_file_name ) {
	#	print STDERR "\n\tItem $full_file_name did not exist\n";
		# create it:
		chdir $base_lib_path;
		`mkdir thisisempty`;
		chdir $base_dir; # back to business
	}
	$mode = (stat($full_file_name))[2];
	print STDERR "\n\tItem $full_file_name is not a directory\n" unless $mode & S_IFDIR;
ok($mode & S_IFDIR, 'empty directory is ok');

# 07: test structure of lib2; should be like:
#
# -rw-r--r--    1 slava    root           18 Aug 29 04:57 file_1.pm
# -rw-r--r--    1 slava    root           18 Aug 29 04:57 file_2.html
# -rw-r--r--    1 slava    root           18 Aug 29 04:57 file_3.txt
# lrwxrwxrwx    1 slava    root           10 Aug 29 04:57 file_4.htm -> file_3.txt
# drwxr-xr-x    3 slava    root         4096 Aug 29 04:57 thishaschild
# drwxr-xr-x    2 slava    root         4096 Aug 29 04:57 thisisempty

	@lib_list = `ls $base_lib_path`;
	@lib_list_full = `ls -l $base_lib_path`;
	$nn = @lib_list;
	$message = join("\t\t",@lib_list_full);
	$good = $nn eq 6;
	$good = $lib_list[0] =~ /^file_1\.pm/ if $good;
	$good = $lib_list[1] =~ /^file_2\.html/ if $good;
	$good = $lib_list[2] =~ /^file_3\.txt/ if $good;
	$good = $lib_list[3] =~ /^file_4\.htm/ if $good;
	$good = $lib_list[4] =~ /^thishaschild/ if $good;
	$good = $lib_list[5] =~ /^thisisempty/ if $good;
	print STDERR "\n\tList of items in $base_lib_path has $nn items:\n\t$message" unless $good;
ok($good, 'lib2 is ok');

# 08: check if we have symlink in lib3:
	$base_lib_path = 'data/testlibs/lib3/';
	$base_dir  = cwd;    # to use for relational paths
	$full_file_name = $base_dir.'/'.$base_lib_path.'file_4.htm';
	unless ( -e $full_file_name ) {
	#	print STDERR "\n\tItem $full_file_name did not exist\n";
		# create symlink:
		chdir $base_lib_path;
		`ln -s file_3.txt file_4.htm`;
		chdir $base_dir; # back to business
	}
	$mode = (stat($full_file_name))[2];
	print STDERR "\n\tItem $full_file_name is not a symlink\n" unless $mode & S_IFLNK;
ok($mode & S_IFLNK, 'symlink is ok');

# 09: check if we have empty directory in lib3:
	$full_file_name = $base_dir.'/'.$base_lib_path.'thisisempty';
	unless ( -e $full_file_name ) {
	#	print STDERR "\n\tItem $full_file_name did not exist\n";
		# create it:
		chdir $base_lib_path;
		`mkdir thisisempty`;
		chdir $base_dir; # back to business
	}
	$mode = (stat($full_file_name))[2];
	print STDERR "\n\tItem $full_file_name is not a directory\n" unless $mode & S_IFDIR;
ok($mode & S_IFDIR, 'empty directory is ok');

# 10: test structure of lib3; should be like:
#
# -rw-r--r--    1 slava    root           18 Aug 29 04:57 file_1.pm
# -rw-r--r--    1 slava    root           18 Aug 29 04:57 file_2.html
# -rw-r--r--    1 slava    root           18 Aug 29 04:57 file_3.txt
# lrwxrwxrwx    1 slava    root           10 Aug 29 04:57 file_4.htm -> file_3.txt
# drwxr-xr-x    2 slava    root         4096 Aug 29 04:57 thisisempty

	@lib_list = `ls $base_lib_path`;
	@lib_list_full = `ls -l $base_lib_path`;
	$nn = @lib_list;
	$message = join("\t\t",@lib_list_full);
	$good = $nn eq 5;
	$good = $lib_list[0] =~ /^file_1\.pm/ if $good;
	$good = $lib_list[1] =~ /^file_2\.HTML/ if $good;
	$good = $lib_list[2] =~ /^file_3\.txt/ if $good;
	$good = $lib_list[3] =~ /^file_4\.htm/ if $good;
	$good = $lib_list[4] =~ /^thisisempty/ if $good;
	print STDERR "\n\tList of items in $base_lib_path has $nn items:\n\t$message" unless $good;
ok($good, 'lib3 is ok');

