use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use Text::ANSI::Printf;
use Data::Dumper;

use Test::More;

my @chars = do {
    map  { pack 'C', $_ }
    grep { $_ != ord '%' }
    map  { $_->[0] .. $_->[1] }
    ( [0x01=>0x07], [0x10=>0x1f], [0x21=>0x7e], [0x81=>0xfe] )
};

my $dot = '.' x @chars;
isnt(Text::ANSI::Printf::sprintf("%s%12s", $dot, "あいうえお"),
		   CORE::sprintf("%s%12s", $dot, "あいうえお"), "normal");

my $s = join '', @chars;
is(Text::ANSI::Printf::sprintf("%s%12s", $s, "あいうえお"),
		 CORE::sprintf("%s%12s", $s, "あいうえお"), "fallback");

done_testing;
