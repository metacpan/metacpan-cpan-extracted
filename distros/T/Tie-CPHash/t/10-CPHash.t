#! /usr/bin/perl
#---------------------------------------------------------------------
# 10-CPHash.t
# Copyright 1997 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the Tie::CPHash module
#---------------------------------------------------------------------

use 5.006;
use strict;
use warnings;

use Test::More 0.88 tests => 23; # done_testing

use Tie::CPHash;

my(%h,$j,$test);

tie(%h, 'Tie::CPHash');
ok(1, 'tied %h');

isa_ok(tied(%h), 'Tie::CPHash');

is($h{Hello}, undef, "Hello not yet defined");

ok(!exists($h{Hello}), "Hello does not exist");

SKIP: {
  skip 'SCALAR added in Perl 5.8.3', 1 unless $] >= 5.008003;
  ok((not scalar %h), 'SCALAR empty');
};

$h{Hello} = 'World';
$j = $h{HeLLo};
is(           $j => 'World',  'HeLLo - World');
is_deeply([keys %h] => ['Hello'],  'last key Hello');

ok(exists($h{Hello}), "Hello now exists");

$h{World} = 'HW';
$h{HELLO} = $h{World};
is(tied(%h)->key('hello') => 'HELLO',  'last key HELLO');

SKIP: {
  skip 'SCALAR added in Perl 5.8.3', 1 unless $] >= 5.008003;
  ok(scalar %h, 'SCALAR not empty');
};

is(delete $h{Hello}, 'HW',  "deleted Hello");
is(delete $h{Hello}, undef, "can't delete Hello twice");

SKIP: {
  skip 'SCALAR added in Perl 5.8.3', 1 unless $] >= 5.008003;
  ok(scalar %h, 'SCALAR still not empty');
};

is(tied(%h)->key('hello') => undef,  'hello not in keys');

tied(%h)->add(qw(HeLlO world));

is($h{world}, 'HW', 'World still exists');
is($h{hello}, 'world', 'hello was pushed');

is(tied(%h)->key('hello') => 'HeLlO',  'hello is HeLlO');
is(tied(%h)->key('world') => 'World',  'world is World');

%h = ();

SKIP: {
  skip 'SCALAR added in Perl 5.8.3', 1 unless $] >= 5.008003;
  ok(!scalar %h, 'SCALAR now empty');
};

{
  my %i;

  tie( %i, 'Tie::CPHash', Hello => 'World');
  is( $i{hello}, 'World', 'initialized from list' );
  is( tied(%i)->key('hello'), 'Hello', 'list remembers case' );
}

{
  tie( my %i, 'Tie::CPHash', qw(Hello World  hello world));

  is( $i{Hello}, 'world', '1 line initialized from list');
  is( tied(%i)->key('Hello'), 'hello', '1 line remembers case');
}

done_testing;

# Local Variables:
# mode: perl
# End:
