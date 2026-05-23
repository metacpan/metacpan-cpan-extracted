use strict;
use warnings;
use Test::More;
use Text::Unpack::Auto qw(guess_unpack auto_unpack);

# Test rle_encode
is(Text::Unpack::Auto::rle_encode("aaabbcc"), "a:3 b:2 c:2 ", "rle_encode works");
is(Text::Unpack::Auto::rle_encode("a"), "a:1 ", "rle_encode with single character works");

# Test rle_decode
is(Text::Unpack::Auto::rle_decode("3:a 2:b 2:c "), "aaabbcc", "rle_decode works");
is(Text::Unpack::Auto::rle_decode("1:a "), "a", "rle_decode with single character works");

# Test rl_to_unpack
is(Text::Unpack::Auto::rle_to_unpack("1:1 0:2 1:1"), "a1x2a1", "rle_to_unpack works");

# Test guess_unpack
is(guess_unpack("a  bb c", "d  ee f"), "a1x2a2x1a1", "guess_unpack works");

# Test auto_unpack
my @lines = (
    "a  bb c",
    "d  ee f"
);
my @expected = (
    ["a", "bb", "c"],
    ["d", "ee", "f"]
);
is_deeply([auto_unpack(@lines)], \@expected, "auto_unpack works");

done_testing();
