#!/usr/bin/perl -w

# Load test the URI::ToDisk module

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		# Setup some things if running outside of a proper Test::Harness
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			catdir('blib', 'arch'),
			'lib',
			);
	}
}

use Test::More tests => 128;
use Scalar::Util 'refaddr';
use URI::ToDisk ();

# Precompute the required paths
my $path1 = catdir(  rootdir(), 'foo'                   );
my $path2 = catdir(  rootdir(), 'foo2'                  );
my $path3 = catfile( rootdir(), 'foo', 'foo', 'bar.txt' );
my $path4 = catdir(  rootdir(), 'foo', 'foo', 'bar'     );





#####################################################################
# Construction

# Create a basic test location
my $location = URI::ToDisk->new( $path1, 'http://foo.com' );
is_normal_location( $location );
is( $location->path, $path1, '->path gives expected value' );
is( $location->uri, 'http://foo.com/', '->uri returns expected value' );
isa_ok( $location->URI, 'URI' );
isa_ok( $location->__as_URI, 'URI' );

# Test equality and overload
my $location2 = URI::ToDisk->new( $path1,  'http://foo.com'  );
my $location3 = URI::ToDisk->new( $path2, 'http://foo.com'   );
my $location4 = URI::ToDisk->new( $path1,  'http://foo2.com' );
is( ($location->__eq($location2)), 1,  '->__eq returns true correctly'  );
is( ($location->__eq($location3)), '', '->__eq returns false correctly' );
is( ($location->__eq($location4)), '', '->__eq returns false correctly' );
is( ($location->__eq(undef)), '',      '->__eq returns false correctly' );
is( ($location->__eq()), '',           '->__eq returns false correctly' );
is( ($location eq $location2), 1,      'eq returns true correctly'      );
is( ($location eq $location3), '',     'eq returns false correctly'     );
is( ($location eq $location4), '',     'eq returns false correctly'     );
is( ($location eq undef), '',          'eq returns false correctly'     );
is( ($location2 eq $location), 1,      'eq returns true correctly'      );
is( ($location3 eq $location), '',     'eq returns false correctly'     );
is( ($location4 eq $location), '',     'eq returns false correctly'     );
is( (undef eq $location), '',          'eq returns false correctly'     );
is( $location, $location,              'Two locations match'            );

my $clone = $location->clone;
is_normal_location( $clone );
is( $clone->path, $path1, '->path gives expected value' );
is( $clone->uri, 'http://foo.com/', '->uri returns expected value' );
isnt( refaddr($clone), refaddr($location), 'Clone is different to original' );

# Test ->params for the equivalent values
my $param1 = URI::ToDisk->param( $location );
isa_ok( $param1, 'URI::ToDisk' );
is( refaddr($param1), refaddr($location), '->param(Location) returns the same location' );
is_deeply( $param1, $location, 'Locations match' );

my $param2 = URI::ToDisk->param( $path1, 'http://foo.com' );
isa_ok( $param2, 'URI::ToDisk' );
is_deeply( $param2, $location, 'Locations match' );

my $param3 = URI::ToDisk->param( [ $path1, 'http://foo.com' ] );
isa_ok( $param3, 'URI::ToDisk' );
is_deeply( $param3, $location, 'Locations match' );





# Do a basic file addition
my $file = $location->catfile( 'foo', 'bar.txt' );
is_normal_location( $file );
isnt( refaddr($location), refaddr($file), '->catfile returns a new object' );
is( $file->path, $path3, '->path gives expected value' );
is( $file->uri, 'http://foo.com/foo/bar.txt', '->uri returns expected value' );

# Has the method call changed the original object?
is_normal_location( $location );
is( $location->path, $path1, '->path gives expected value' );
is( $location->uri, 'http://foo.com/', '->uri returns expected value' );





# Do a basic directory addition
my $dir = $location->catdir( 'foo', 'bar' );
is_normal_location( $file );
isnt( refaddr($location), refaddr($dir), '->catfile returns a new object' );
is( $dir->path, $path4, '->path gives expected value' );
is( $dir->uri, 'http://foo.com/foo/bar', '->uri returns expected value' );

# Has the method call changed the original object?
is_normal_location( $location );
is( $location->path, $path1, '->path gives expected value' );
is( $location->uri, 'http://foo.com/', '->uri returns expected value' );

exit();





# Do a series of basic checks on a location
sub is_normal_location {
	my $object = shift;
	ok(     defined $object, '->new returns defined' );
	ok(     $object, '->new returns true' );
	isa_ok( $object, 'URI::ToDisk' );
	ok(     defined $object->path, '->path returns defined' );
	ok(     ! ref $object->path, "->path doesn't return a reference" );
	ok(     length $object->path, "->path doesn't return a zero length string" );
	ok(     defined $object->URI, "->URI returns defined" );
	ok(     ref $object->URI, "->URI returns a reference" );
	isa_ok( $object->URI, 'URI' );
	isnt(   refaddr($object->URI), refaddr($object->URI), '->URI returns a clone' );
	ok(     defined $object->uri, '->uri returns defined' );
	ok(     ! ref $object->uri, "->uri doesn't return a reference" );
	ok(     length $object->uri, "->uri doesn't return a null string" );
	ok(     length "$object", "Location stringifies to a non-null string" );
	is(     $object->uri, "$object", "Location stringifies to the ->uri value" );
}

1;
