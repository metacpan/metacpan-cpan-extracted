#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 18;

use lib 't/lib';
use TestClass;

BEGIN { use_ok 'Test::Mocha' }

my $spy = spy( TestClass->new );

ok( $spy->isa('TestClass'), 'isa() called' );
is( ( inspect { $spy->isa('TestClass') } )[0],
    'isa("TestClass")', '... and inspected' );
called_ok { $spy->isa('TestClass') } '... and verified';

ok( $spy->DOES('TestClass'), 'DOES() called' );
is( ( inspect { $spy->DOES('TestClass') } )[0],
    'DOES("TestClass")', '... and inspected' );
called_ok { $spy->DOES('TestClass') } '... and verified';

ok( $spy->does('TestClass'), 'does() called' );
is( ( inspect { $spy->does('TestClass') } )[0],
    'does("TestClass")', '... and inspected' );
called_ok { $spy->does('TestClass') } '... and verified';

ok( $spy->can('get'), 'can() called' );
is( ( inspect { $spy->can('get') } )[0], 'can("get")', '... and inspected' );
called_ok { $spy->can('get') } '... and verified';

is( $spy->ref, 'TestClass', 'ref() called as a method' );
is( ref($spy), 'TestClass', '... or as a function (via UNIVERSAL::ref)' );
is( ( my $call = ( inspect { $spy->ref } )[0] ), 'ref()', '... and inspected' );
# Ensure UNIVERSAL::ref is not recorded as caller when it intercepts the call
is( ( $call->caller )[0], __FILE__, '... and caller is not UNIVERSAL::ref' );
called_ok { $spy->ref } &times(2), '... and verified';
