#!perl -w
use strict;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Tree::PseudoIncLib;
use Log::Log4perl;
use Cwd;
use Test::Simple tests => 7;

Log::Log4perl::init( 'data/log.config' );

# 01: _dir_description():
	my $dir_de = debug_dir_description('test');
	print STDERR "\n\t_dir_description basic test returned $dir_de\n" unless $dir_de eq 3;
ok($dir_de eq 3, 'basic _dir_description is OK');

# 02: debug_dir_description_case_insensitive();
	my $di = debug_dir_description_case_insensitive('test');
	print STDERR "\n\t_dir_description case insensitive lest returned $di\n" unless $di eq 3;
	ok($di eq 3, 'case insensitive _dir_description is OK');
# 03: _object_list():
	my $olis = debug_object_list('test');
	print STDERR "\n\t_object_list test returned $olis\n" unless $olis eq 6;
	ok($olis eq 6, '_object_list works');
# 04: from_scratch():
	my $frsc = debug_from_scratch('test');
	print STDERR "\n\tfrom_scratch test returned $frsc\n" unless $frsc eq 13;
	ok($frsc eq 13, 'from_scratch works');
# 05:
	my $dsh = debug_shaded_names('test');
	print STDERR "\n\tshaded_names test returned '$dsh'\n" unless $dsh eq 'file_1.pm';
	ok($dsh eq 'file_1.pm', 'shaded_names works');
# 06:
	my $test_06 = debug_simple_names('test');
	print STDERR "\n\tlist_simple_keys test returned $test_06\n" unless $test_06 > 10;
	ok($test_06 > 10, 'list_simple_keys() works');
# 07:
	my $test_07 = debug_descript_names('test');
	print STDERR "\n\tlist_descript_keys test returned $test_07\n" unless $test_07 > 16;
	ok($test_07 > 16, 'list_descript_keys() works');

sub debug_descript_names {
	# this should be used when debug_from_scratch is done.

	my $test_flag = shift; # silent test ordered
	my $dir = getcwd;
	my @pseudo_inc = (	$dir.'/data/testlibs/lib1',
				$dir.'/data/testlibs/lib2',);
	my $dobj = Tree::PseudoIncLib->new(
		max_nodes	=> 100,
		p_INC => \@pseudo_inc,
		skip_empty_dir	=> 0, # keep them
	);

	$dobj->from_scratch(lib_name => 'fiction');
	return $dobj->list_descript_keys;
}

sub debug_simple_names {
	# this should be used when debug_from_scratch is done.

	my $test_flag = shift; # silent test ordered
	my $dir = getcwd;
	my @pseudo_inc = (	$dir.'/data/testlibs/lib1',
				$dir.'/data/testlibs/lib2',);
	my $dobj = Tree::PseudoIncLib->new(
		max_nodes	=> 100,
		p_INC => \@pseudo_inc,
		skip_empty_dir	=> 0, # keep them
	);

	$dobj->from_scratch(lib_name => 'fiction');
	return $dobj->list_simple_keys;
}

sub debug_dir_description_case_insensitive {
	# _dir_description is tested on one level data structure only,
	# because I do not like to print the result from _dir_description format.

	my $test_flag = shift; # silent test ordered
	my $dir = getcwd;
	my @pseudo_inc = ( $dir.'/data/testlibs/lib1',);
	my $dobj = Tree::PseudoIncLib->new(
		max_nodes	=> 10,
		p_INC => \@pseudo_inc,
	);
	my @pril;
        my $allow_masks = []; # to select files
        map { push @{$allow_masks},$_->{mask} } @{$dobj->{allow_files}};

	my $desc = $dobj->_dir_description(
		root_dir		=> $dir.'/data/testlibs/lib3',
		pseudo_cpan_root_name	=> '',
		parent_index		=> 'parin',
		parent_depth_level	=> 1,
		prior_libs		=> \@pril,
		inc_lib			=> $dir.'/data/testlibs/lib3',
		allow_masks		=> $allow_masks,
	);
	# in order to use this sub in automated tests I return the size of the description:
	return scalar(@{$desc});
}

sub debug_dir_description {
	# _dir_description is tested on one level data structure only,
	# because I do not like to print the result from _dir_description format.

	my $test_flag = shift; # silent test ordered
	my $dir = getcwd;
	my @pseudo_inc = ( $dir.'/data/testlibs/lib1',);
	my $dobj = Tree::PseudoIncLib->new(
		max_nodes	=> 100,
		p_INC => \@pseudo_inc,
	);
	my @pril;
        my $allow_masks = []; # to select files
        map { push @{$allow_masks},$_->{mask} } @{$dobj->{allow_files}};

	my $desc = $dobj->_dir_description(
		root_dir		=> $dir.'/data/testlibs/lib1',
		pseudo_cpan_root_name	=> '',
		parent_index		=> 'parin',
		parent_depth_level	=> 1,
		prior_libs		=> \@pril,
		inc_lib			=> $dir.'/data/testlibs/lib1',
		allow_masks		=> $allow_masks,
	);
	# in order to use this sub in automated tests I return the size of the description:
	return scalar(@{$desc});
}

sub debug_object_list {
	# this should be used when debug_dir_description is done.

	my $test_flag = shift; # silent test ordered
	my $dir = getcwd;
	my @pseudo_inc = ( $dir.'/data/testlibs/lib2',);
	my $dobj = Tree::PseudoIncLib->new(
		max_nodes	=> 100,
		p_INC => \@pseudo_inc,
	);
	my @pril;
        my $allow_masks = []; # to select files
        map { push @{$allow_masks},$_->{mask} } @{$dobj->{allow_files}};

	my $desc = $dobj->_dir_description(
		root_dir		=> $dir.'/data/testlibs/lib2',
		pseudo_cpan_root_name	=> '',
		parent_index		=> 'parin',
		parent_depth_level	=> 1,
		prior_libs		=> \@pril,
		inc_lib			=> $dir.'/data/testlibs/lib2',
		allow_masks		=> $allow_masks,
	);
	$dobj->{descript} = $dobj->_object_list ($desc);
	# in order to use this sub in automated tests I return the size of the description:
	return scalar(@{$dobj->{descript}});
}

sub debug_from_scratch {
	# this should be used when debug_object_list is done.

	my $test_flag = shift; # silent test ordered
	my $dir = getcwd;
	my @pseudo_inc = (	$dir.'/data/testlibs/lib1',
				$dir.'/data/testlibs/lib2',);
	my $dobj = Tree::PseudoIncLib->new(
		max_nodes	=> 100,
		p_INC => \@pseudo_inc,
		skip_empty_dir	=> 0, # keep them
	);

	$dobj->from_scratch(lib_name => 'fiction');
	# in order to use this sub in automated tests I return the size of the description:
	return scalar(@{$dobj->{descript}});
}

sub debug_shaded_names {
	# this should be used when debug_from_scratch is done.

	my $test_flag = shift; # silent test ordered
	my $dir = getcwd;
	my @pseudo_inc = (	$dir.'/data/testlibs/lib1',
				$dir.'/data/testlibs/lib2',);
	my $dobj = Tree::PseudoIncLib->new(
		max_nodes	=> 100,
		p_INC => \@pseudo_inc,
		skip_empty_dir	=> 0, # keep them
	);

	$dobj->from_scratch(lib_name => 'fiction');
	my @arr;
	map {push @arr, $_->{name} if $_->{shaded_by_lib} } @{$dobj->{descript}};
	return join(', ', @arr);
}
#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


