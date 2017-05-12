use strict;
use warnings;

#
# Minimal PSGI application for benchmarking.
#

my $app = sub {
  my $env = shift;
  return [200, [], []];
};
$app
