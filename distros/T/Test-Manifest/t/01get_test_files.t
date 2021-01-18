use strict;

use Test::More 0.95;

use File::Copy qw(copy);
use File::Spec;

use Test::Manifest qw(get_t_files manifest_name);
use lib './t';
use Test::Manifest::Tempdir qw(prepare_tmp_dir);

my $tmp_dir = prepare_tmp_dir();
copy($_, $tmp_dir) or die "Cannot copy $_ to $tmp_dir: $!"
	for qw( test_manifest test_manifest_levels );
chdir $tmp_dir or die "Cannot chdir to $tmp_dir: $!";

my $expected = join " ", map { File::Spec->catfile( "t", $_ ) } qw(
	00load.t 01get_test_files.t 01make_test_manifest.t
	leading_space.t trailing_space.t
	);

my @tests = split /\s+/, $expected;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest setup => sub {
	my $in_name       = 'test_manifest';
	my $manifest_name = manifest_name();

	open my $in,  '<:utf8', $in_name       or fail( "Could not read $in_name: $!" );
	open my $out, '>:utf8', $manifest_name or fail( "Could not write $manifest_name: $!" );

	print {$out} $_ while( <$in> );

	ok( -e $in_name,       "$in_name exists in top level directory" );
	ok( -e $manifest_name, "$manifest_name exists" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest scalar_version => sub {
	my $string = get_t_files();

	is( $string, $expected, "Single string version of tests is right" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest array_version => sub {
	my @array = get_t_files();

	foreach my $i ( 0 .. $#array ) {
		is( $array[$i], $tests[$i], "Test file $i has expected name" );
		}
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest remove_manifest => sub {
	local $SIG{__WARN__} = sub { 1 };

	if( $^O eq 'VMS' ) {	# http://perldoc.perl.org/perlvms.html#unlink-LIST
		1 while ( unlink manifest_name() );
		}
	else {
		unlink manifest_name();
		}

	-e manifest_name() ?
		fail( "test_manifest still around after unlink!" ) :
		pass( "test_manifest unlinked" ) ;

	my $string = get_t_files();

	ok( ! $string, "Nothing returned when test_manifest does not exist (scalar)" );

	my @array = get_t_files();

	ok( ! $string, "Nothing returned when test_manifest does not exist (list)" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest levels => sub {
	local $Test::Harness::verbose = 1;
	copy( 'test_manifest_levels', manifest_name() );

	my @expected = (
		[ qw( 00load.t 01get_test_files.t 01make_test_manifest.t
			leading_space.t pod_coverage.t trailing_space.t 99pod.t ) ],
		[ qw( 00load.t 01get_test_files.t pod_coverage.t) ],
		[ qw( 00load.t 01get_test_files.t 01make_test_manifest.t
			pod_coverage.t ) ],
		[ qw( 00load.t 01get_test_files.t 01make_test_manifest.t
			leading_space.t pod_coverage.t trailing_space.t ) ],
		);

	foreach my $level ( 0 .. 3 ) {
		my $string = get_t_files( $level );
		my $expected = join ' ', map { File::Spec->catfile( 't', $_ ) }
			@{ $expected[$level] };
		is( $string, $expected, "Level $level version of tests is right" );
		}

	};

done_testing();
