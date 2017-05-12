use Test::Given;
use strict;
use warnings;

describe 'Exception in Invariant And', sub {
  context 'time to die' => sub {
    Invariant sub { 1 };
    And sub { die 'Invariant And died' };
    Then sub { 'Passing Then' };
  };

  context 'another test' => sub {
    Then sub { 'Passing test reached' };
  };

  Then sub { 'Passing outer Then'};
};
