use Test::Given;
require 't/test_helper.pl';
use strict;
use warnings;

our ($lines);
my $re = qr/\brequires previous .* clause in current context\b/;

describe 'And as first term of test file' => sub {
  Given lines => sub { run_spec('t/t/die-and-file.t') };
  Then sub { contains($lines, $re) };
  And  sub { not contains($lines, qr/never reached/) };
};

describe 'And as first term of context' => sub {
  Given lines => sub { run_spec('t/t/die-and-context.t') };
  Then sub { contains($lines, $re) };
  And  sub { not contains($lines, qr/never reached/) };
};
