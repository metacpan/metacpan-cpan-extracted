use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 5;
use Text::Hunspell;

my $speller = Text::Hunspell->new(qw(./t/test.aff ./t/test.dic));
die unless $speller;
ok($speller, qq(Created a Text::Hunspell object [$speller]));

my $word = q(lótól);
ok(
    $speller->check($word),
    qq(Word '$word' should be in the test dictionary)
);

$word = q(lóotól);
ok(
    ! $speller->check($word),
    qq(Word '$word' shouldn't be in the test dictionary)
);

# Check spell suggestions
my $misspelled = q(lóo);
my @suggestions = $speller->suggest($misspelled);
ok(scalar @suggestions > 0, q(Got some suggestions));

is_deeply(
    \@suggestions => [ qw(lói ló lót) ],
    q(List of suggestions should be correct)
);
