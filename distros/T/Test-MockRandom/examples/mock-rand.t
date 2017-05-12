package main;
use strict;
use warnings;
use lib 'lib';

use Test::More tests => 2;
use Test::MockRandom 'Test::Package';

srand( 0.23, 0.32 );

is( Test::Package::foo(), 0.23 );
is( Test::Package::foo(), 0.32 );

package Test::Package;

sub foo { return rand() };

