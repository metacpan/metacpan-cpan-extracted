#! perl

use strict;
use warnings;
use Test::More 0.88 tests => 3;

use constant::Atom;

ok(1, "using constant::Atom with no Atom names should be fine");

eval {
    my $atom = constant::Atom->new('main', undef);
};
ok($@, "second argument to new() must be non-undef");

eval {
    my $atom = constant::Atom->new(undef, 'yellow');
};
ok($@, "first argument to new must be non-undef")

