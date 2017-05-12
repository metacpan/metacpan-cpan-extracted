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
  test_out('not ok 1 - Script t/bin/four.pl runs');
  test_fail(+2);
  test_err(qr{^# 4 - (?:Using.*\n# )?Standard Error\n?$});
  my $rv = script_runs('t/bin/four.pl');
  test_test('Bad script returns false');
  is( $rv, '', 'script_runs returns true as a convenience' );
}

SCOPE: {
  # Repeat with a custom message
  test_out('not ok 1 - It worked');
  test_fail(+2);
  test_err(qr{^# 4 - (?:Using.*\n# )?Standard Error\n?$});
  my $rv = script_runs('t/bin/four.pl', 'It worked');
  test_test('Bad script returns false');
  is( $rv, '', 'script_runs returns true as a convenience' );
}
