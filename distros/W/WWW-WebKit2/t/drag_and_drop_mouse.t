use strict;
use warnings;
use utf8;

use Test::More;
use lib 'lib';
use FindBin qw($Bin $RealBin);
use lib "$Bin/../../Gtk3-WebKit2/lib";
use URI;


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