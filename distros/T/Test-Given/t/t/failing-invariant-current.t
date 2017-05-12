use Test::Given;
use strict;
use warnings;

describe 'Failing Invariant - current context', sub {
  Invariant sub { undef };
  Then sub { 'Passing Then' };
};
