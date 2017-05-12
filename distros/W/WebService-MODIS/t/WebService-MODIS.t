# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl WebService::MODIS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use LWP::Online 'online';
use Test::More;

use_ok('WebService::MODIS');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# commented out, since it takes to long
#SKIP: {
#  use WebService::MODIS;
#  skip 'Tests need online connection', 1, unless online();
#  ok(initCache, 'initialize memory cache');
#}

done_testing();
