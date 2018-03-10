use lib '.';
use t::Helper;

$ENV{MOJO_SELENIUM_DRIVER} = t::Helper->mock_driver;
my $t = t::Helper->t->driver_args({browser_name => 'dummy'});

is_deeply($t->driver_args, {browser_name => 'dummy'}, 'driver_args set');
isa_ok($t->driver, 't::Selenium::MockDriver');

note $ENV{MOJO_SELENIUM_DRIVER} .= '&browser_name=firefox%20browser%2C2.0&port=4444';

$t = t::Helper->t;
is_deeply $t->driver_args, {}, 'environment does not set driver_args';

is_deeply(
  $t->driver,
  {browser_name => 'firefox browser,2.0', port => 4444, ua => $t->ua},
  'environment is passed on to t::Selenium::MockDriver::new()',
);

done_testing;
