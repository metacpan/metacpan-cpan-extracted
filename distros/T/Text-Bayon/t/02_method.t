use strict;
use warnings;
use Text::Bayon;
use Test::More tests => 3;

my $bayon = Text::Bayon->new;
can_ok($bayon, 'new');
can_ok($bayon, 'clustering');
can_ok($bayon, 'classify');