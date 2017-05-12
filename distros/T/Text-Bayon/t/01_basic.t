use strict;
use warnings;
use Text::Bayon;
use Test::More tests => 1;

my $bayon = Text::Bayon->new;
isa_ok($bayon, 'Text::Bayon');