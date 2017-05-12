use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::MethodFixtures;

$ENV{TEST_MF_MODE} = 'record';

ok my $mocker
    = Test::MethodFixtures->new( { storage => '+TestMethodFixtures::Dummy', } ),
    "got mocker";

is $mocker->mode, 'record', 'testing TEST_MF_MODE environment variable';

done_testing();

