use strict;
use warnings;

use Test::More;
use Test::Snapshots;

Test::Snapshots::multiple(1);

test_all_snapshots("eg/multiple");

