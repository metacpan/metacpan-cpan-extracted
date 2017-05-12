#!perl

use strict;
use warnings;

use Test::More;
use Wurm::mob;

my $meal = Wurm::mob->new({env => { }});
isa_ok($meal, 'Wurm::mob');

done_testing();
