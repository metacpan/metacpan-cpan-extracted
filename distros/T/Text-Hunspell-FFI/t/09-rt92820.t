use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Text::Hunspell::FFI;

plan skip_all => 'Test requires development files'
  unless -r 't/spanish.aff';

plan tests => 3;

my $speller = Text::Hunspell::FFI->new(qw(./t/spanish.aff ./t/spanish.dic));
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
