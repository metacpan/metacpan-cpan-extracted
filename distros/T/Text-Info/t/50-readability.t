use Test::More;
use utf8;

use Text::Info;

#
# FRES: Tested against https://readability-score.com/
#
my $text = Text::Info->new(
    text     => "Rudolph Agnew, 55 years old and former chairman of Consolidated Gold Fields PLC, was named a director of this British industrial conglomerate.",
    language => 'en',
);

is( $text->readability->fres, '34.53', 'FRES value is OK!' );

#
# FRES: Norwegian
#
$text = Text::Info->new(
    text     => "– Dette er den minst gjennomtenkte valgkampsaken i Norge på mange år. Her hadde Oslo Ap før første gang på mange år en god mulighet til å vinne makten i Oslo. Jeg skjønner ikke hvordan det er mulig å gjøre et så dårlig strategisk valg. De har selv bidratt til at Fabian Stang og Stian Berger Røsland mest sannsynlig får fortsette, sier pr-nestor Hans Geelmuyden, sjef i Geelmuyden Kiese.",
    language => 'no',
);

is( $text->readability->fres, '47.10', 'FRES value is OK!' );

#
# FGLS: https://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_tests#Flesch.E2.80.93Kincaid_grade_level
#
$text = Text::Info->new(
    text     => "The Australian platypus is seemingly a hybrid of a mammal and reptilian creature",
    language => 'en',
);

is( $text->readability->fkrgl, '13.08', 'FGLS value is OK!' );

#
# The End
#
done_testing;
