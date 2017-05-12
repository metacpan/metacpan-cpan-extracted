use strict;

use Test;
use XML::SAX::Machine;

my @tests = (
["A",        1],
["Foo_1",    1],
["Foo::Bar", 0],
["Foo-Bar",  0],
["1Foo",     0],
["Foo\n",    0],
["Foo ",     0],
[" Foo",     0],
["Foo,",     0],
["foo,",     0],
["1",        0],
);

plan tests => scalar @tests;

for (@tests) {
    ok XML::SAX::Machine::_valid_name $_->[0], $_->[1], $_->[0];
}

