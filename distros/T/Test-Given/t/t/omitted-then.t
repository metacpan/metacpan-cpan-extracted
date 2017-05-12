use Test::Given;
use strict;
use warnings;

our ($subject);

describe 'Then-less', sub {
  context 'Outer Then-less', sub {
    Given subject => sub { 'subject' };
    Invariant sub { 1 };
    Then sub { $subject eq 'subject' };

    context 'Inner Then-less', sub {};
  };
};
