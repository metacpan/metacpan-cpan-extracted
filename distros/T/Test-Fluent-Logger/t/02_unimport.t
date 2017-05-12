use strict;
use warnings;
use utf8;

use Test::More;
no Test::Fluent::Logger;

is Test::Fluent::Logger::is_active, 0;

done_testing;

