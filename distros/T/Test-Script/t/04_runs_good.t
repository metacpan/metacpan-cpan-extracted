use strict;
use warnings;
use Test::Builder::Tester tests => 4;
use Test::More;
use Test::Script;

# Until CPAN #14389 is fixed, create a false HARNESS_ACTIVE value
# if it doesn't exists to prevent a warning in test_test.
$ENV{HARNESS_ACTIVE} ||= 0;





#####################################################################
# Main Testing

SCOPE: {
  # Run a test for a known-good program
  test_out("ok 1 - Script t/bin/good.pl runs");
  my $rv = script_runs('t/bin/good.pl');
  test_test('Good script returns true');
  is( $rv, 1, 'script_runs returns true as a convenience' );
}

SCOPE: {
  # Repeat with a custom message
  test_out("ok 1 - It worked");
  my $rv = script_runs('t/bin/good.pl', 'It worked');
  test_test('Good script returns true');
  is( $rv, 1, 'script_runs returns true as a convenience' );
}
