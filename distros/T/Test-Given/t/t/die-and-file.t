use Test::Given;
use strict;
use warnings;

describe 'And first in file', sub {
  And sub { 'die' };
  warn "never reached\n";
};
