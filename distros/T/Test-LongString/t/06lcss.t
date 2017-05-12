#!perl -w

use strict;

use Test::More tests => 11;

BEGIN { use_ok "Test::LongString" }

my ($off, $len) = Test::LongString::_lcss ( "xyzzx", "abcxyzefg" );
my $longest = substr('xyzzx', $off, $len);
is ( $longest, "xyz", "xyzzx vs abcxyzefg" );

($off, $len) = Test::LongString::_lcss ( "abcxyzzx", "abcxyzefg" );
$longest = substr("abcxyzzx", $off, $len);
is ( $longest, "abcxyz", "abcxyzzx vs abcxyzefg" );

($off, $len) = Test::LongString::_lcss ( "foobar", "abcxyzefg" );
$longest = substr("foobar", $off, $len);
is ( $longest, 'f', "foobar vs abcxyzefg" );

my $needle = "i pushed the lazy dog into a creek, the quick brown fox told me to";
my $haystack = "the quick brown fox jumps over the lazy dog";

($off, $len) = Test::LongString::_lcss ( $needle, $haystack );
$longest = substr($needle, $off, $len);
is ( $longest, "the quick brown fox ", "the quick brown fox" );

($off, $len) = Test::LongString::_lcss ( $haystack, $needle );
$longest = substr($haystack, $off, $len);
is ( $longest, "the quick brown fox ", "the quick brown fox (reverse args)" );

$haystack = "why did the quick brown fox jumps over the lazy dog";
($off, $len) = Test::LongString::_lcss ( $needle, $haystack );
$longest = substr($needle, $off, $len);
is ( $longest, " the quick brown fox ", "why did the quick brown fox" );

($off, $len) = Test::LongString::_lcss ( 'ABBAGGG', 'HHHHZZAB');
$longest = substr("ABBAGGG", $off, $len);
is ($longest, 'AB', 'ABBA at the beginning and end');

($off, $len) = Test::LongString::_lcss ( 'HHHHZZAB', 'ABBAGGG');
$longest = substr("HHHHZZAB", $off, $len);
is ($longest, 'AB', 'ABBA at the beginning and end (reverse args)');

($off, $len) = Test::LongString::_lcss ( 'b', 'ab' );
$longest = substr("b", $off, $len);
is($longest, 'b', 'bug in LCSS');

($off, $len) = Test::LongString::_lcss ( "123", "ABCD" );
$longest = substr("123", $off, $len);
is($longest, '', 'empty when there is no common substring');
