use Mojo::Base -strict;
use Test::Mojo::WithRoles 'Selenium';
use Test::More;

$ENV{MOJO_SELENIUM_DRIVER} = mock_driver();
my $t = Test::Mojo::WithRoles->new->driver_args({browser_name => 'dummy'});

is_deeply($t->driver_args, {browser_name => 'dummy'}, 'driver_args set');
isa_ok($t->driver, 'Selenium::MockDriver');

$ENV{MOJO_SELENIUM_DRIVER} .= '&browser_name=firefox%20browser%2C2.0&port=4444';

$t = Test::Mojo::WithRoles->new;
is_deeply $t->driver_args, {}, 'environment does not set driver_args';

is_deeply(
  $t->driver,
  {browser_name => 'firefox browser,2.0', port => 4444, ua => $t->ua},
  'environment is passed on to Selenium::MockDriver::new()',
);

done_testing;

sub mock_driver {
  return eval <<'HERE' || die $@;
  package Selenium::MockDriver;
  sub debug_on {}
  sub default_finder {}
  sub get {}
  sub new {shift; return bless {@_}, 'Selenium::MockDriver'}
  $INC{'Selenium/MockDriver.pm'} = 'Selenium::MockDriver';
HERE
}
