# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 1;

SKIP:
{
  skip "Test::Pod not installed", 1 unless eval "require Test::Pod";
  Test::Pod->import;
  use Tie::Array::BoundedIndex;
  pod_file_ok($INC{"Tie/Array/BoundedIndex.pm"});
}
