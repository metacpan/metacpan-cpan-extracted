use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 7;
use Text::Hunspell::FFI;

my $speller = Text::Hunspell::FFI->new(qw(./t/test.aff ./t/test.dic));
ok($speller, qq(Created a Text::Hunspell::FFI object [$speller]));

# Sample analysis:
#
#    'st:ló po:noun ts:NOM al:lovak is:ABL'
#
my $word = q(lótól);
my $analysis = $speller->analyze($word);

ok($analysis, q(Got something back));
note("Analysis result: [$analysis]");

# I'm a total newbie in dictionary stuff
ok($analysis =~ m{st:ló}, q(Stemming root));
ok($analysis =~ m{po:noun}, q(Word supposed to be a noun));
ok($analysis =~ m{ts:NOM}, q(Have no idea));
ok($analysis =~ m{al:lovak}, q(Also here, no idea));
ok($analysis =~ m{is:ABL}, q(Guess what?));

