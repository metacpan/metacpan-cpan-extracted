use Test::Given;
use strict;
use warnings;

describe 'Failing Then', sub {
  Then sub { undef };
};
