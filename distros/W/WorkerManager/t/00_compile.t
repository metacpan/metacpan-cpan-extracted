use strict;
use warnings;
use Test::More;

use_ok $_ for (qw(
    WorkerManager
    WorkerManager::TheSchwartz
    WorkerManager::Client::TheSchwartz
));

done_testing;
