#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 14;

BEGIN { use_ok('Text::Hyphen') };

ok(my $hyp = new Text::Hyphen, 'hyphenator loaded');

sub is_hyph ($$) {
    my ($word, $expected) = @_;
    my $result = $hyp->hyphenate($word);
    is($result, $expected, qq{hyphenated "$word"});
}

is_hyph 'representation', 'rep-re-sen-ta-tion';
is_hyph 'presents', 'presents';
is_hyph 'declination', 'dec-li-na-tion';
is_hyph 'peter', 'pe-ter';
is_hyph 'going', 'go-ing';
is_hyph 'leaving', 'leav-ing';
is_hyph 'multiple', 'mul-ti-ple';
is_hyph 'playback', 'play-back';
is_hyph 'additional', 'ad-di-tion-al';
is_hyph 'maximizes', 'max-i-mizes';
is_hyph 'programmable', 'pro-grammable';
is_hyph 'table', 'ta-ble';
