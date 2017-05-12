use strict;
use warnings;

use Test::More;
use Test::Snapshots;

plan skip_all => 'Invest more time in testing the timeout';

Test::Snapshots::timeout(3);
test_all_snapshots("eg/timeout");

