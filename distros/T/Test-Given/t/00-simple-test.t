use Test::Given;
require 't/test_helper.pl';
use strict;
use warnings;

our ($lines);

describe 'Output of simple passing test suite' => sub {
  Given lines => sub { run_spec('t/t/simple-test.t') };
  Then sub { contains($lines, qr/All tests successful/) };
  Then sub { contains($lines, qr/\* Simple Test/) };
  Then sub { contains($lines, qr/\$subject eq 'result'/) };
  Then sub { not contains($lines, qr/\$subject ne 'subject'/) };
};
