#!/usr/bin/perl

use warnings;
use strict;

use lib 't/tlib';

use Test::More no_plan =>;

use aliased::factory ();

use aliased::factory SBOO => 'SillyBunchOfObjects';

my $base = 'SillyBunchOfObjects';
my $sboo = SBOO->new;
ok($sboo);
is($sboo->classname, $base);


is(SBOO->Foo->new->classname, $base . '::Foo');
is(SBOO->Bar->new->classname, $base . '::Bar');

is(SBOO->Foo->Bar->new->classname, $base . '::Foo::Bar');
is(SBOO->Foo->Baz->new->classname, $base . '::Foo::Baz');
is(SBOO->Foo->Bort->new->classname, $base . '::Foo::Bort');

is(SBOO->can('thbbittyboppity'), undef);
is(SBOO->Foo->can('thbbittyboppity'), undef);

#  make sure error message references caller
is(eval {SBOO->thbbittyboppity}, undef);
my $pm   = $base . '/thbbittyboppity.pm';
my $file = __FILE__;
like($@, qr{^Can't locate \Q$pm\E in \@INC .* at \Q$file\E line });

# we can actually hop over a missing part of the tree with can()
is(SBOO->Bar->can('Baz::Bort')->()->new->classname, $base . '::Bar::Baz::Bort');

# vim:ts=2:sw=2:et:sta
