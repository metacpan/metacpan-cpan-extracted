#!perl -T
use strict;
use warnings;

use Test::More;
use Test::Proto::TestCase;

ok (1, 'ok is ok');

sub tc { Test::Proto::TestCase->new(@_); }

ok (ref tc, 'tc is an object');
ok (tc->isa('Test::Proto::TestCase'), 'tc is a TestCase');

my $bob = tc(name=>'Bob');
ok (ref $bob, 'tc is an object');
is ($bob->name, 'Bob', 'Name works');
#ok (tc->isa('Test::Proto::TestCase'), 'tc is a TestCase');

# tc->name
# tc->code
# tc->data

done_testing;

