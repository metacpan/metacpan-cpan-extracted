######################################################################
# Test suite for Text::TermExtract
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
use Text::TermExtract;

plan tests => 3;

my $text = q{
Angelika Amerikas Wahlkampfmaschine läuft auf Hochtouren und seit Monaten bombardieren uns die Medien mit Prognosen, Debatten und Werbespots der Kandidaten zum amerikanischen Präsidentschaftsamt. Am Ende der Vorwahlen kristallisieren sich zwei Kandidaten heraus, einer für die republikanische und einer für die demokratische Partei -- und einer davon wird dann bei den wirklichen Wahlen im November Präsident der USA. In der Regel ist das Interesse an diesen Vorwahlen relativ gering und die Wahlbeteiligung extrem niedrig, doch dieses Jahr sieht alles anders aus.};

my $ext = Text::TermExtract->new(languages => ['en', 'de']);

my @words = $ext->terms_extract( $text, { max => 3 } );

is($words[0], "kandidaten", "keywords");
is($words[1], "vorwahlen", "keywords");
is($words[2], "amerikanischen", "keywords");
