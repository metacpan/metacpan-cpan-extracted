use strict;
use warnings;

use Test::More;
use Test::Snapshots;

Test::Snapshots::combine(1);
test_all_snapshots("eg/samedir_combine");

