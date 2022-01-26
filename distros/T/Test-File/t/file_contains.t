use strict;
use warnings;

use Test::Builder::Tester;
use Test::More 1;
use Test::File;

require "./t/setup_common";

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

my $file = 'min_file';
my $contents = do { open FH, $file; local $/; <FH> }; close FH;
my $pattern1    = 'x' x 11; $pattern1    = qr/(?mx:^ $pattern1    $)/;
my $pattern2    = 'x' x 40; $pattern2    = qr/(?mx:^ $pattern2    $)/;
my $bad_pattern = 'x' x 20; $bad_pattern = qr/(?mx:^ $bad_pattern $)/;


# like : single pattern

test_out( "ok 1 - min_file contains $pattern1" );
file_contains_like( $file, $pattern1 );
test_test();

test_out( "not ok 1 - bmoogle contains $pattern1" );
test_diag( 'file [bmoogle] does not exist' );
test_fail(+1);
file_contains_like( 'bmoogle', $pattern1 );
test_test();

SKIP: {
skip "Superuser has special privileges",             1 if is_unix_superuser();
skip "Windows has a different idea of readable",     1 if is_win32();
skip "Not possible to make file unreadable on MSYS", 1 if is_msys();
test_out( "not ok 1 - not_readable contains $pattern1" );
test_diag( 'file [not_readable] is not readable' );
test_fail(+1);
file_contains_like( 'not_readable', $pattern1 );
test_test();
}

test_out( "not ok 1 - min_file contains $bad_pattern" );
test_fail(+2);
like_diag($contents, $bad_pattern, "doesn't match");
file_contains_like( 'min_file', $bad_pattern );
test_test();


# unlike : single pattern

test_out( "ok 1 - min_file doesn't contain $bad_pattern" );
file_contains_unlike( $file, $bad_pattern );
test_test();

test_out( "not ok 1 - bmoogle doesn't contain $bad_pattern" );
test_diag( 'file [bmoogle] does not exist' );
test_fail(+1);
file_contains_unlike( 'bmoogle', $bad_pattern );
test_test();

SKIP: {
skip "Superuser has special privileges",             1 if is_unix_superuser();
skip "Windows has a different idea of readable",     1 if is_win32();
skip "Not possible to make file unreadable on MSYS", 1 if is_msys();
test_out( "not ok 1 - not_readable doesn't contain $bad_pattern" );
test_diag( 'file [not_readable] is not readable' );
test_fail(+1);
file_contains_unlike( 'not_readable', $bad_pattern );
test_test();
}

test_out( "not ok 1 - min_file doesn't contain $pattern1" );
test_fail(+2);
like_diag($contents, $pattern1, "matches");
file_contains_unlike( 'min_file', $pattern1 );
test_test();


# like : multiple patterns

test_out( "ok 1 - min_file contains $pattern1" );
test_out( "ok 2 - min_file contains $pattern2" );
file_contains_like( $file, [ $pattern1, $pattern2 ] );
test_test();

test_out( "ok 1 - file has the goods" );
test_out( "ok 2 - file has the goods" );
file_contains_like( $file, [ $pattern1, $pattern2 ], 'file has the goods' );
test_test();

test_out( "not ok 1 - bmoogle contains $pattern1" );
test_diag( 'file [bmoogle] does not exist' );
test_fail(+1);
file_contains_like( 'bmoogle', [ $pattern1, $pattern2 ] );
test_test();

SKIP: {
skip "Superuser has special privileges",             1 if is_unix_superuser();
skip "Windows has a different idea of readable",     1 if is_win32();
skip "Not possible to make file unreadable on MSYS", 1 if is_msys();
test_out( "not ok 1 - not_readable contains $pattern1" );
test_diag( 'file [not_readable] is not readable' );
test_fail(+1);
file_contains_like( 'not_readable', [ $pattern1, $pattern2 ] );
test_test();
}

test_out( "ok 1 - min_file contains $pattern1" );
test_out( "not ok 2 - min_file contains $bad_pattern" );
test_fail(+2);
like_diag($contents, $bad_pattern, "doesn't match");
file_contains_like( 'min_file', [ $pattern1, $bad_pattern ] );
test_test();


# unlike : multiple patterns

test_out( "ok 1 - min_file doesn't contain $bad_pattern" );
test_out( "ok 2 - min_file doesn't contain $bad_pattern" );
file_contains_unlike( $file, [ $bad_pattern, $bad_pattern ] );
test_test();

test_out( "ok 1 - file has the goods" );
test_out( "ok 2 - file has the goods" );
file_contains_unlike( $file, [ $bad_pattern, $bad_pattern ], 'file has the goods' );
test_test();

test_out( "not ok 1 - bmoogle doesn't contain $bad_pattern" );
test_diag( 'file [bmoogle] does not exist' );
test_fail(+1);
file_contains_unlike( 'bmoogle', [ $bad_pattern, $bad_pattern ] );
test_test();

SKIP: {
skip "Superuser has special privileges",             1 if is_unix_superuser();
skip "Windows has a different idea of readable",     1 if is_win32();
skip "Not possible to make file unreadable on MSYS", 1 if is_msys();
test_out( "not ok 1 - not_readable doesn't contain $bad_pattern" );
test_diag( 'file [not_readable] is not readable' );
test_fail(+1);
file_contains_unlike( 'not_readable', [ $bad_pattern, $bad_pattern ] );
test_test();
}

test_out( "ok 1 - min_file doesn't contain $bad_pattern" );
test_out( "not ok 2 - min_file doesn't contain $pattern1" );
test_fail(+2);
like_diag($contents, $pattern1, "matches");
file_contains_unlike( 'min_file', [ $bad_pattern, $pattern1 ] );
test_test();


done_testing();


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub like_diag {
	my ($string, $pattern, $verb) = @_;

	my $diag = ' ' x 18 . "'$string'\n";
	$diag .= sprintf("%17s '%s'", $verb, $pattern);
	$diag =~ s/^/# /mg;

	test_err($diag);
	}
