#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
BEGIN {
   plan skip_all => 'This module is Win32 only' unless
      $^O eq 'MSWin32' || $^O eq 'cygwin'
};
use Test::Deep;
use Win32::ServiceManager;

ok(my $sm = Win32::ServiceManager->new, 'instantiate');

cmp_deeply(
   [$sm->_nssm_install(qw(foo bar baz))],
   [qw(nssm_64.exe install foo bar baz)],
   'nssm install seems to work',
);

cmp_deeply(
   [$sm->_sc_install(qw(foo bar baz))],
   [qw(sc create foo), 'binpath= "bar" baz'],
   'sc install seems to work',
);

cmp_deeply(
   [$sm->_sc_configure('foo', {display => 'Foo', depends => 'MSSQL\Apache2.2'})],
   [qw(sc config foo),
      'DisplayName= "Foo"',
      'type= own start= auto depend= "MSSQL\Apache2.2"',
   ],
   'sc configure seems to work',
);

cmp_deeply(
   [$sm->_sc_configure('foo', {display => 'Foo', depends => [qw(MSSQL Apache2.2)]})],
   [qw(sc config foo),
      'DisplayName= "Foo"',
      'type= own start= auto depend= "MSSQL\Apache2.2"',
   ],
   'sc configure with arrayref deps seems to work',
);

cmp_deeply(
   [$sm->_sc_configure('foo', {display => 'Foo', user => 'domain\wes'})],
   [qw(sc config foo),
      'DisplayName= "Foo"',
      'type= own start= auto obj= "domain\wes"',
   ],
   'sc configure auth ok',
);

cmp_deeply(
   [$sm->_sc_configure('foo', {display => 'Foo', user => 'wes', password => 'gnarl'})],
   [qw(sc config foo),
      'DisplayName= "Foo"',
      'type= own start= auto obj= "wes" password= "gnarl"',
   ],
   'sc configure auth ok',
);

cmp_deeply(
   [$sm->_sc_configure('foo', {display => 'Foo', start => 'delayed-auto'})],
   [qw(sc config foo),
      'DisplayName= "Foo"',
      'type= own start= delayed-auto',
   ],
   'sc configure start ok',
);

done_testing;
