#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 2;

require Variable::Temp;

my %syms = (
 temp     => '\[$@%]',
 set_temp => '\[$@%];$',
);

for (sort keys %syms) {
 eval { Variable::Temp->import($_) };
 is $@,            '',        "import $_";
 is prototype($_), $syms{$_}, "prototype $_";
}
