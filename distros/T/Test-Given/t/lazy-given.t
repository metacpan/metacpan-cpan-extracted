use Test::Given;
use strict;
use warnings;

our ($param);

describe 'Lazy given' => sub {
  Given '&subject' => sub { sub { "Subject is $param" } };
  Given param => sub { 'default' };

  Then sub { &subject eq 'Subject is default' };

  context 'with setup parameter' => sub {
    Given param => sub { 'nested' };

    Then sub { &subject eq 'Subject is nested' };

    context 'with setup parameter' => sub {
      Given param => sub { 'more nested' };

      Then sub { &subject eq 'Subject is more nested' };
    };
  };
};
