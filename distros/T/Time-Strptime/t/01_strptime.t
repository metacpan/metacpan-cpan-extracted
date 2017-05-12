use strict;

use Time::Strptime qw/strptime/;
use Time::Strptime::TimeZone;
use Test::More tests => 2;

local $Time::Strptime::TimeZone::DEFAULT = 'GMT';

my ($epoch, $offset) = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 01:23:45');
is $epoch,  1388539425, 'epoch  OK';
is $offset, 0,          'offset OK';
