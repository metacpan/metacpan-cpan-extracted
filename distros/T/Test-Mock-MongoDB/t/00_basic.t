use strict;
use warnings;

use Test::More;

my $pkg = 'Test::Mock::MongoDB';

use_ok($pkg);

my $mock = new_ok($pkg);

can_ok($mock, qw| get_client get_database get_collection get_cursor |);

done_testing;
