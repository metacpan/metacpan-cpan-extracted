use strict;
use warnings;

use less  'explanation';
use fewer 'excuses';
use more  'responsibility';

use Test::More 'no_plan';

ok(   less->of('explanation'));
ok(   fewer->of('explanation'));
ok( ! more->of('explanation'));

ok(   less->of('excuses'));
ok(   fewer->of('excuses'));
ok( ! more->of('excuses'));

ok(! less->of('responsibility'));
ok(! fewer->of('responsibility'));
ok(  more->of('responsibility'));
