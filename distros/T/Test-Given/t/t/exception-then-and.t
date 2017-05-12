use Test::Given;
use strict;
use warnings;

describe 'Exception in Then And', sub {
  Then sub { 'Passing test before' };
  Then sub { 'Passing Then' };
  And  sub { die 'And died' };
  Then sub { 'Passing test after' };
};
