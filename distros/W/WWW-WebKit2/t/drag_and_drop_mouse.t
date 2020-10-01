use strict;
use warnings;
use utf8;

use Test::More;
use lib 'lib';
use FindBin qw($Bin $RealBin);
use lib "$Bin/../../Gtk3-WebKit2/lib";
use URI;

#Running tests as root will sometimes spawn an X11 that cannot be closed automatically and leave the test hanging
plan skip_all => 'Tests run as root may hang due to X11 server not closing.' unless $>;

use_ok 'WWW::WebKit2';

my $webkit = WWW::WebKit2->new(xvfb => 1);

eval { $webkit->init; };
if ($@ and $@ =~ /\ACould not start Xvfb/) {
    $webkit = WWW::WebKit2->new();
    $webkit->init;
}

elsif($@) {
    diag($@);
    fail('init webkit');
}

$webkit->open("$Bin/test/drag_and_drop.html");

$webkit->mouse_input_drag_and_drop_to_object('id=dragme', 'id=target');
ok($webkit->is_element_present('xpath=//div[@id="target"]//div[@id="dragme"]'), 'Element has been successfully dragged by the mouse');

done_testing;
