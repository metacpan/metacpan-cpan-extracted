#!/usr/bin/perl 

# Test things needed on the local filesystem

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use File::Spec::Functions ':ALL';
use File::Flat;

# Create the test directory containing a test file
my $testdir  = catdir('t', 'data');
my $testfile = catfile( $testdir, 'foo', 'testfile' );
File::Flat->write( $testfile, 'This is some content' );
END {
	system( "chmod -R u+w $testdir" );
	File::Flat->remove( $testdir ) if -e $testdir;
}

# Does chmod behave the way we wan't
is( system( "chmod -R a-w $testdir/*" ), 0, 'chmod a-w is supported'  );
is( system( "chmod -R a+rX $testdir" ),  0, 'chmod a+rX is supported' );
is( system( "chmod -R u+w $testdir" ),   0, 'chmod u+w is supported'  );

# Is the CVS client new enough
my @version = `cvs -v`;
chomp @version;
my $ver = $version[1] =~ /\b(1\.[\d\.p]+)/ ? $1 : undef;
ok( $ver, "Found CVS version" );
my @ver = split /\./, $ver;
my $new_enough = ( $ver[0] and $ver[0] >= 1 and $ver[1] and $ver[1] >= 11 );
ok( $new_enough, 'CVS version is new enough' );

exit(0);
