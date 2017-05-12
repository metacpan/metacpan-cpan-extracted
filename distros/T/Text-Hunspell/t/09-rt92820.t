use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 3;
use Text::Hunspell;

my $speller = Text::Hunspell->new(qw(./t/spanish.aff ./t/spanish.dic));
die unless $speller;
ok($speller, q{Loaded the spanish dictionary});

my $word = q(agarró);
ok(
    $speller->check($word),
    qq('$word' should be found in the spanish dictionary)
);

$word = q(agarróso);
ok(
    ! $speller->check($word),
    qq('$word' shouldn't be in the spanish dictionary)
);
