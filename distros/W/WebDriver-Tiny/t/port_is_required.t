use strict;
use warnings;

use Test::More tests => 1;
use WebDriver::Tiny;

eval { WebDriver::Tiny->new };

is $@, 'WebDriver::Tiny - Missing required parameter "port" at ' . __FILE__
    . ' line ' . ( __LINE__ - 3 ) . ".\n", 'Port is required';
