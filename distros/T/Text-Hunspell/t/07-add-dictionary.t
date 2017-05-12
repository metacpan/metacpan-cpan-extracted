use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 4;
use Text::Hunspell;

my $speller = Text::Hunspell->new(qw(./t/test.aff ./t/test.dic));
die unless $speller;
ok($speller, qq(Created a Text::Hunspell object [$speller]));

my $word = q(munkey);
ok(
    !$speller->check($word),
    qq(Word '$word' shouldn't be in the test dictionary)
);

ok(
    !$speller->add_dic(q(./t/supp.dic)),
    q(Added a supplemental dictionary)
);

ok(
    $speller->check($word),
    qq(Word '$word' is in the supplemental dictionary)
);
