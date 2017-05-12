#! /usr/bin/perl -Tw

use strict;
use warnings;
use Sub::Uplevel;
use Carp;
use Test::Builder::Tester tests => 3;
use Test::More;

BEGIN { use_ok( 'Test::Exception' ) };

# This test in essence makes sure that no false
# positives are encountered due to @DB::args being part
# of the stacktrace
# The test seems rather complex due to the fact that
# we make a really tricky stacktrace

test_false_positive($_) for ('/fribble/', qr/fribble/);

sub throw { confess ('something unexpected') }
sub try { throw->(@_) }
sub test_false_positive {
  my $test_against_desc = my $test_against = shift;

  if (my $ref = ref ($test_against) ) {
    $test_against_desc = "$ref ($test_against_desc)"
      if $test_against_desc !~ /^\Q$ref\E/;
  }

  test_out("not ok 1 - threw $test_against_desc");
  test_fail(+1);
  throws_ok { try ('fribble') } $test_against;
  my $exception = $@;

  test_diag("expecting: $test_against_desc");
  test_diag(split /\n/, "found: $exception");
  test_test("$test_against_desc in stacktrace ignored");
}
