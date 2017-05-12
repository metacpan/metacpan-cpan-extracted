use Test::Given;
use strict;
use warnings;

describe 'Failing And', sub {
  Then sub { 'Passing Then' };
  And  sub { undef };
};
