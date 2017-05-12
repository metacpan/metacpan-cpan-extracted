#!/usr/bin/perl -w
#^^^^^^^^^^^^^^^^^ Just to make my editor use syntax highlighting

package main;

use strict;
use warnings;

use Test::More 'tests' => 6;

use Time::AutoRes qw(time sleep alarm usleep ualarm);

ok( UNIVERSAL::can('main', 'time'),   'main::time() defined'   );
ok( UNIVERSAL::can('main', 'sleep'),  'main::sleep() defined'  );
ok( UNIVERSAL::can('main', 'alarm'),  'main::alarm() defined'  );

ok( UNIVERSAL::can('main', 'usleep'), 'main::usleep() defined' );

ok( UNIVERSAL::can('main', 'ualarm'), 'main::ualarm() defined' );

ok( usleep(1), 'usleep' );
