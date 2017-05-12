#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/base2';
use Test::More;

no circular::require;

use_ok('Foo');
is(Foo->bar, "bar", "Polymorphism");

my $ok = eval "use base 'BadWolf'";
my $err = $@;
ok(!$ok, "use base 'Some Bad File' should throw an exception");
like($err, qr/Base class package "BadWolf" is empty/, "correct exception");

done_testing;
