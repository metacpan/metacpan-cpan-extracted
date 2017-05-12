use Test::Given;
use strict;
use warnings;

describe 'Failing Invariant - ancestor context', sub {
  Invariant sub { undef };
  context 'in sub-context' => sub {
    Then sub { 'Inner passing Then' };
  };
  Then sub { 'Outer passing Then' };
};
