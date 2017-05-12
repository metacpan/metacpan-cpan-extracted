use strict;
use warnings;
use utf8;

use Test::Builder::Tester;
use Test::More 0.95;
use Test::File;
use Test::utf8;

# Hello world! I am a string. Russian, courtesy of Google Translate
my $string1 = 'Привет мир!';
my $string2 = 'Я строкой';
my $encoding = 'KOI8-R';

require "./t/setup_common";

my $file = '$file';
open my $fh, '>', $file or print "bail out! Could not write to $file: $!";
binmode($fh, ":encoding($encoding)");
$fh->print("$string1$/$/$/");
$fh->print("$string2$/");
$fh->close;

my $contents = do {
     open $fh, '<', $file;
     binmode($fh, ":encoding($encoding)");
     local $/;
     <$fh>;
};
$fh->close;

my $pattern1 = qr/$string1/;
my $pattern2 = qr/$string2/;
my $bad_pattern = 'x' x 20; $bad_pattern = qr/(?m:^$bad_pattern$)/;

# like : single pattern

test_out( "ok 1 - $file contains $pattern1" );
file_contains_encoded_like( $file, $encoding, $pattern1 );
test_test();

test_out( "not ok 1 - $file contains $bad_pattern" );
test_fail(+2);
like_diag($contents, $bad_pattern, "doesn't match");
file_contains_encoded_like( '$file', $encoding, $bad_pattern );
test_test();

# unlike : single pattern

test_out( "ok 1 - $file doesn't contain $bad_pattern" );
file_contains_encoded_unlike( $file, $encoding, $bad_pattern );
test_test();

test_out( "not ok 1 - $file doesn't contain $pattern1" );
test_fail(+2);
like_diag($contents, $pattern1, "matches");
file_contains_encoded_unlike( '$file', $encoding, $pattern1 );
test_test();

# like : multiple patterns

test_out( "ok 1 - $file contains $pattern1" );
test_out( "ok 2 - $file contains $pattern2" );
file_contains_encoded_like( $file, $encoding, [ $pattern1, $pattern2 ] );
test_test();

test_out( "ok 1 - file has the goods" );
test_out( "ok 2 - file has the goods" );
file_contains_encoded_like( $file, $encoding, [ $pattern1, $pattern2 ], 'file has the goods' );
test_test();

test_out( "ok 1 - $file contains $pattern1" );
test_out( "not ok 2 - $file contains $bad_pattern" );
test_fail(+2);
like_diag($contents, $bad_pattern, "doesn't match");
file_contains_encoded_like( '$file', $encoding, [ $pattern1, $bad_pattern ] );
test_test();

# unlike : multiple patterns

test_out( "ok 1 - $file doesn't contain $bad_pattern" );
test_out( "ok 2 - $file doesn't contain $bad_pattern" );
file_contains_encoded_unlike( $file, $encoding, [ $bad_pattern, $bad_pattern ] );
test_test();

test_out( "ok 1 - file has the goods" );
test_out( "ok 2 - file has the goods" );
file_contains_encoded_unlike( $file, $encoding, [ $bad_pattern, $bad_pattern ], 'file has the goods' );
test_test();

test_out( "ok 1 - $file doesn't contain $bad_pattern" );
test_out( "not ok 2 - $file doesn't contain $pattern1" );
test_fail(+2);
like_diag($contents, $pattern1, "matches");
file_contains_encoded_unlike( '$file', $encoding, [ $bad_pattern, $pattern1 ] );
test_test();

done_testing();

sub like_diag
{
	my ($string, $pattern, $verb) = @_;

	my $diag = ' ' x 18 . "'$string'\n";
	$diag .= sprintf("%17s '%s'", $verb, $pattern);
	$diag =~ s/^/# /mg;

	test_err($diag);
}
