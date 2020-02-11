use strict;
use warnings;
use utf8;

use Test::More;

use lib "t/lib";
use TestApp;

BEGIN {
    use_ok 'Test::WWW::WebKit2::Catalyst';
}

my $sel = Test::WWW::WebKit2::Catalyst->new(app => 'TestApp', xvfb => 1);

eval { $sel->init; };
if ($@ and $@ =~ /\ACould not start Xvfb/) {
    $sel = Test::WWW::WebKit2::Catalyst->new(app => 'TestApp');
    $sel->init;
}
ok(1, 'init done');

$sel->open_ok("http://localhost:$ENV{CATALYST_PORT}/index");

done_testing;
