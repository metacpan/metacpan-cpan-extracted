#!/usr/bin/perl
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
use Text::Quoted;

# I don't really care what the results are, so long as we don't
# segfault.

my $ntk = <<'NTK';
 _   _ _____ _  __ <*the* weekly high-tech sarcastic update for the uk>
| \ | |_   _| |/ / _ __   __2002-07-26_ o join! mail an empty message to
|  \| | | | | ' / | '_ \ / _ \ \ /\ / / o ntknow-subscribe@lists.ntk.net
| |\  | | | | . \ | | | | (_) \ v  v /  o website (+ archive) lives at:
|_| \_| |_| |_|\_\|_| |_|\___/ \_/\_/   o     http://www.ntk.net/ 
NTK

ok(extract($ntk), "It's not pretty, but at least it works");

is(
    Text::Quoted::combine_hunks( extract($ntk) ),
    $ntk,
    "round-trips okay",
);
