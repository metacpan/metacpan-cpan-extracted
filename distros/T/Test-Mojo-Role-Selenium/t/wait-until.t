use lib '.';
use t::Helper;
use Test::More;

use Mojolicious::Lite;
get '/' => sub { shift->render(text => 'dummy') };

$ENV{MOJO_SELENIUM_DRIVER} = t::Helper->mock_driver;
my $t = t::Helper->t;

# Avoid failing tests from wait_until()
Mojo::Util::monkey_patch(ref($t), _test => sub { return shift });

$t::Helper::x = 1;
$t->wait_until(sub { $_->x });
is $t::Helper::x, 2, 'wait_until';

$t->wait_until(sub { $_->x; 0 }, {interval => 5, timeout => 0.2});
is $t::Helper::x, 2, 'wait_until timeout';

$t->wait_until(sub { shift->driver->x; 0 }, {interval => 0.01, timeout => 0.2});
ok + ($t::Helper::x > 10), "wait_until interval ($t::Helper::x)";

no warnings 'redefine';
my @die;
*Test::More::diag = sub { push @die, @_ };
$t->wait_until(sub { die 'yikes!' }, {debug => 1, interval => 0.1, timeout => 0.3});
like "@die", qr{yikes}, 'debug';

done_testing;
