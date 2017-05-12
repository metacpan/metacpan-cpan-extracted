use Mojo::Base -strict;
use Test::Mojo::WithRoles 'Selenium';
use Test::More;

use Mojolicious::Lite;
get '/' => sub { shift->render(text => 'dummy') };

$ENV{MOJO_SELENIUM_DRIVER} = mock_driver();
my $t = Test::Mojo::WithRoles->new;

# Avoid failing tests from wait_until()
Mojo::Util::monkey_patch(ref($t), _test => sub { return shift });

my $i = 1;
$t->wait_until(sub { $_->x });
is $i, 2, 'wait_until';

$t->wait_until(sub { $_->x; 0 }, {interval => 5, timeout => 0.2});
is $i, 2, 'wait_until timeout';

$t->wait_until(sub { shift->driver->x; 0 }, {interval => 0.01, timeout => 0.2});
ok + ($i > 10), "wait_until interval ($i)";

no warnings 'redefine';
my @die;
*Test::More::diag = sub { push @die, @_ };
$t->wait_until(sub { die 'yikes!' }, {debug => 1, interval => 0.1, timeout => 0.3});
like "@die", qr{yikes}, 'debug';

done_testing;

sub mock_driver {
  return eval <<'HERE' || die $@;
  package Test::Mojo::Role::Selenium::MockDriver;
  sub debug_on {}
  sub default_finder {}
  sub get {}
  sub x { $i++ }
  sub new {bless {}, 'Test::Mojo::Role::Selenium::MockDriver'}
  $INC{'Test/Mojo/Role/Selenium/MockDriver.pm'} = 'Test::Mojo::Role::Selenium::MockDriver';
HERE
}
