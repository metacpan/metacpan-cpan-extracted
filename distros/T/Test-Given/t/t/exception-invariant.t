use Test::Given;
use strict;
use warnings;

describe 'Exception in Invariant', sub {
  context 'time to die' => sub {
    Invariant sub { die 'Invariant died' };
    Then sub { 'Passing Then' };
  };

  context 'another test' => sub {
    Then sub { 'Passing test reached' };
  };

  Then sub { 'Passing outer Then'};
};
