#!/usr/bin/perl
use strict;
use warnings;

use utf8;

use Test::More qw/no_plan/;

BEGIN { use_ok('Text::Hyphen::RU') };

ok(my $hyp = new Text::Hyphen::RU, 'hyphenator loaded');

sub is_hyph ($$) {
    my ($word, $expected) = @_;
    my $result = $hyp->hyphenate($word);
    is($result, $expected, qq{hyphenated another word});
}

is_hyph 'бездн', 'бездн';
is_hyph 'вакуумирование', 'ва-ку-у-ми-ро-ва-ние';
is_hyph 'выскажу', 'вы-ска-жу';
is_hyph 'соткешь', 'со-ткешь';
