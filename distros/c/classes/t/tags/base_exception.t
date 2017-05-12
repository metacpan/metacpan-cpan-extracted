# $Id: base_exception.t 127 2006-08-23 20:39:21Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 3;
}

package SomeXBase;
use classes new=>'classes::new_only', mixes=>'classes::Throwable';

package ExcsBase;
use classes
    base_exception => 'SomeXBase',
    exceptions => 'X::EB1',
;
package main;
isa_ok(X::EB1->new, 'SomeXBase');
ok(!X::EB1->new->isa('X::classes'), 'not classes');
ok(!X::EB1->new->isa('X::classes::traceable'), 'not traceable');

