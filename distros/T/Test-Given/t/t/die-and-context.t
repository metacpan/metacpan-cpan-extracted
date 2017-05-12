use Test::Given;
use strict;
use warnings;

describe 'And first in context', sub {
  Given subject => sub { 'subject' };
  And subject => sub { 'and' };

  context 'time to die' => sub {
    And sub { 'die' };
    warn "never reached - inner\n";
  };
  warn "never reached - outer\n";
};
