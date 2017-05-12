use strict;
use warnings;
use utf8;

use Test::More;
use FindBin qw($Bin);

BEGIN {
    use_ok 'Test::WWW::WebKit';
}

my $sel = Test::WWW::WebKit->new();
ok($sel->init);

$sel->open_ok("$Bin/test/attribute.html");

$sel->refresh_ok;

$sel->attribute_like('id=test@class', qr/foo/);
$sel->attribute_unlike('id=test@class', qr/qux/);

$sel->open("$Bin/test/key_press.html");
$sel->key_press('css=body', '\027');
$sel->wait_for_alert_ok('27');

done_testing;
