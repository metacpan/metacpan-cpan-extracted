use warnings;
use strict;
use Test::More;
use Text::Fuzzy::PP;
use utf8;

my @titles = (
    'Until We Meet Again',
    'Mother',
    'Ningen Gyorai Kaiten',
    'Christ in Bronze',
    'Jun\'ai monogatari',
    'Hiroshima mon amour',
    'The Ugly American',
    'Kanojo to kare',
    'The Woman in the Dunes',
    'The X from Outer Space',
    'Mujo',
    'Lady Snowblood',
    'Lone Wolf and Cub: Baby Cart in the Land of Demons',
    'ESPY',
    'Kimi yo fundo no kawa o watare',
    'Blue Christmas',
    'The Gate of Youth',
    'Crazy Fruit',
    'Nankyoku monogatari',
);

my $tf = Text::Fuzzy::PP->new ('Motherう');

my $nearest = $tf->nearest (\@titles);
is ($nearest, 1, "test unicode versus non-unicode");
done_testing ();
