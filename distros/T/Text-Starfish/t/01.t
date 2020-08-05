#!/usr/bin/perl
use Test::More;
# tests using Test::More.  Maybe all tests should go here.

use_ok("Text::Starfish");

# Testing internal function _index
my ($i,$l) = Text::Starfish::_index("abctestd", "test");
is($i,3,'_index');
is($l,4);
($i,$l) = Text::Starfish::_index("abctestabc", "ab");
is($i,0); is($l,2);
($i,$l) = Text::Starfish::_index("abctestabc", "ab", 1);
is($i,7); is($l,2);
my $s = "This is some text, and then again some text, etc.";
($i,$l) = Text::Starfish::_index($s, qr/i.*?me/);
is(substr($s,$i,$l), "is is some");
($i,$l) = Text::Starfish::_index($s, qr/i.*?me/, 3);
is(substr($s,$i,$l), "is some");
($i,$l) = Text::Starfish::_index($s, qr/i.*?me/, 6);
is(substr($s,$i,$l), "in some");

done_testing();
