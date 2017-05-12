use strict;
use warnings;

use Test::More tests => 7;
use Text::Hunspell;

my $speller = Text::Hunspell->new(qw(./t/test.aff ./t/test.dic));
die unless $speller;
ok($speller, qq(Created a Text::Hunspell object [$speller]));

my $word = q(lótól);
ok(
    $speller->check($word),
    qq(Word '$word' found in first dictionary)
);

my $speller2 = Text::Hunspell->new(qw(./t/supp.aff ./t/supp.dic));
die unless $speller2;
ok($speller2, qq(Created another Text::Hunspell object [$speller2]));

ok(
    $speller->check($word),
    qq(Word '$word' found in first dictionary)
);

ok(
    !$speller2->check($word),
    qq(Word '$word' not found in second dictionary)
);

$word = q(munkey);
ok(
    !$speller->check($word),
    qq(Word '$word' not found in first dictionary)
);

ok(
    $speller2->check($word),
    qq(Word '$word' found in second dictionary)
);
