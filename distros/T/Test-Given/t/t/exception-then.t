use Test::Given;
use strict;
use warnings;

describe 'Exception in Then', sub {
  Then sub { 'Passing test before' };
  Then sub { die 'Then died' };
  Then sub { 'Passing test after' };
};
