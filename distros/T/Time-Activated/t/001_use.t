use strict;
use warnings;
use Test::More tests => 2;

use lib 'lib';
use lib '../lib';

use_ok('DateTime::Format::ISO8601');
use_ok('Time::Activated');
