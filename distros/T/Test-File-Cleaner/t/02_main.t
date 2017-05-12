#!/usr/bin/perl -w

# Main testing of Test::File::Cleaner

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 'tests' => 40;
use File::stat ();
use File::Spec::Functions ':ALL';

# Load the module to test
use Test::File::Cleaner ();
BEGIN {
	$Test::File::Cleaner::DEBUG = 0;
}

# Prepare
my $root   = catdir( 't',   'data' );
my $dir1   = catdir( $root, 'dir1' );
my $states = -d catdir( $root, '.svn') ? 21 : 2; # Support development testing

sub touch($) {
	open( FILE, ">$_[0]" ) or die "open: $!";
	print FILE "Foo";
	close FILE;
	1;
}





#####################################################################
# Constructor

my $Cleaner1 = Test::File::Cleaner->new( $root );
isa_ok( $Cleaner1, 'Test::File::Cleaner' );
is( $Cleaner1->path, $root, '->path return the path' );
is( scalar(keys %{$Cleaner1->{state}}), $states, "New cleaner has $states state file" );






#####################################################################
# Create a whole bunch of normal files

SCOPE: {
	ok( mkdir($dir1), 'Created test dir 1' );
	my @normal = qw{one two three four five six};
	@normal = map { catfile( $dir1, $_ ) } @normal;
	foreach my $file ( @normal ) {
		ok( touch $file, "Wrote test file $file" );
	}

	ok( $Cleaner1->clean, 'Cleaner says it cleaned' );
	foreach ( $dir1, @normal ) {
		ok( ! -e $_, "Cleaner removed file/dir '$_'" );
	}
}




#####################################################################
# Repeat with DESTROY

SCOPE: {
	ok( mkdir($dir1), 'Created test dir 1' );
	my @normal = qw{one two three four five six};
	@normal = map { catfile( $dir1, $_ ) } @normal;
	foreach my $file ( @normal ) {
		ok( touch $file, "Wrote test file $file" );
	}

	ok( $Cleaner1->DESTROY, 'Cleaner says it cleaned' );
	foreach ( $dir1, @normal ) {
		ok( ! -e $_, "Cleaner removed file/dir '$_'" );
	}
}





#####################################################################
# Change some permissions

my $Cleaner2 = Test::File::Cleaner->new( $root );

# Just test the worst possible...
my $README = catfile( $root, 'README' );
ok( chmod( 0000, $README ), 'Changed README mode to 0000' );
ok( $Cleaner2->clean, 'Cleaner cleans' );
ok( File::stat::stat($README)->mode & 07777, 'Mode is no longer 0000' );





#####################################################################
# Remove a file we theoretically can't

my $bad = catfile( $root, 'bad' );
ok( touch $bad, 'Created bad' );
ok( -f $bad, 'Created bad' );
ok( chmod(0000, $bad), 'Set bad permissions to 0000' );
$Cleaner2->clean;
ok( ! -e $bad, 'Bad got removed ok' );

1;
