use v5.18;

use strict;
use utf8;

use Text::Util::Chinese;
use Test2::V0;

my @numbers = (1..10);
my $num_iter = sub { shift @numbers };

my $even_num_iter = Text::Util::Chinese::grep_iterator(
   $num_iter,
   sub { $_ % 2 == 0 },
);

my @even_num;
while ( defined(my $n = $even_num_iter->()) ) {
      push @even_num, $n;
}

is \@even_num, [2, 4, 6, 8, 10];

done_testing;
