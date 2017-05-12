use common::sense;
use Test::More;

use lib "t/lib";
use TestApp;

BEGIN {
    use_ok 'Test::WWW::WebKit::Catalyst';
}

my $sel = Test::WWW::WebKit::Catalyst->new(app => 'TestApp', xvfb => 1);

eval { $sel->init; };
if ($@ and $@ =~ /\ACould not start Xvfb/) {
    $sel = Test::WWW::WebKit::Catalyst->new(app => 'TestApp');
    $sel->init;
}
ok(1, 'init done');

$sel->open_ok("http://localhost:$ENV{CATALYST_PORT}/index");

done_testing;
