# $Id: exceptions.t 127 2006-08-23 20:39:21Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 11;
}

use_ok('classes');

lives_and( sub {
    classes::classes(exceptions => 'X::One');
    isa_ok(X::One->new, 'X::main');
    isa_ok(X::One->new, 'X::classes');
    isa_ok(X::One->new, 'X::classes::traceable');
}, 'automatic inheritance tree' );

lives_and( sub {
    classes::classes(def_base_exception=>'X::classes');
    classes::classes(name=>'blah',exceptions => 'X::Two');
    isa_ok(X::One->new, 'X::classes');
    ok(!X::Two->new->isa('X::main'));
    ok(!X::Two->new->isa('X::classes::traceable'));
}, 'altered inheritance tree' );

throws_ok( sub {
    X::One->throw;
}, 'X::One');

throws_ok( sub {
    X::One->throw;
}, 'X::classes');

throws_ok( sub {
    X::One->throw;
}, 'X::classes::traceable');

throws_ok( sub {
    X::One->throw;
}, 'X::main');

