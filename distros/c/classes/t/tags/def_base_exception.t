# $Id: def_base_exception.t 127 2006-08-23 20:39:21Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 4;
}

use classes def_base_exception => 'X::classes';

package Blah;
use classes
    exceptions => 'X::One',
;
package main;
isa_ok(X::One->new, 'X::classes');
isa_ok(X::One->new, 'X::One');
ok(!X::One->new->isa('X::main'), 'not main');
ok(!X::One->new->isa('X::classes::traceable'), 'not traceable');

