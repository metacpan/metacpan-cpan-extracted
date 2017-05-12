use Test::Given;
use strict;
use warnings;

describe 'Exception in Given', sub {
  context 'time to die' => sub {
    Given sub { die 'Given died' };
    Then sub { 'Passing inner Then' };
  };

  context 'another test' => sub {
    Then sub { 'Passing test never reached' };
  };

  Then sub { 'Passing outer Then'};
};
