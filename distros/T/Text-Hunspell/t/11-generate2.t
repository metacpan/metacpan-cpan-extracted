use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 1;
use Text::Hunspell;

my $speller = Text::Hunspell->new(qw(./t/morph.aff ./t/morph.dic));
die unless $speller;

is $speller->generate2('phenomenon', ['is:plur']), 'phenomena', ' phenomenon is:plur => phenomena';
