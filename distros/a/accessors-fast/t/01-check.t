#!/usr/bin/env perl -w

use strict;
use warnings;
use lib::abs qw(../lib);

package X;

use accessors::fast qw(a b);

package Y;

use base 'X';
use accessors::fast qw(c);

package A;
use accessors::fast 'z';


package Z;
use base 'Y', 'A';

package main;

use Test::NoWarnings;
use Test::More tests => 24;

ok(X->can('a'),'X.a');
ok(X->can('b'),'X.b');
ok(!X->can('c'),'X.c');

ok(Y->can('a'),'Y.a');
ok(Y->can('b'),'Y.b');
ok(Y->can('c'),'Y.c');

ok(A->can('z'),'A.z');
ok(!A->can('a'),'A.a');
ok(!A->can('b'),'A.b');
ok(!A->can('c'),'A.c');

ok(Z->can('a'),'Z.a');
ok(Z->can('b'),'Z.b');
ok(Z->can('c'),'Z.c');
ok(Z->can('z'),'Z.z');

isa_ok(my $z = Z->new(),'A');
isa_ok(Z->new(),'X');
isa_ok(Z->new(),'Y');
isa_ok(Y->new(),'X');

ok !tied %$z, 'object is tied';

is_deeply [ X->field_list ], [ qw(a b) ], 'X.fields';
is_deeply [ Y->field_list ], [ qw(a b c) ], 'Y.fields';
is_deeply [ A->field_list ], [ qw(z) ], 'A.fields';
is_deeply [ Z->field_list ], [ qw(a b c z) ], 'Z.fields';

{
	no warnings 'accessors::fast';
	Z->new( 1..3 );
}

exit 0;
