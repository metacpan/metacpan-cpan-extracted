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
elsif ($@) {
    diag($@);
    fail('init webkit');
}

$webkit->open("$Bin/test/drag_and_drop.html");

$webkit->native_drag_and_drop_to_object('id=dragme', 'id=target');
ok($webkit->is_element_present('xpath=//div[@id="target"]//div[@id="dragme"]'), 'Element has been successfully dragged');

my $slider_location = '//input[@id="slider_range"]';
my $resolved_location = $webkit->resolve_locator($slider_location);
my ($target_x, $target_y) = $resolved_location->get_screen_position;
my $slider_value = $resolved_location->get_value;

$webkit->native_drag_and_drop_to_position(
    $slider_location,
    $target_x - 5,
    $target_y
);

my $new_slider_value = $resolved_location->get_value;
isnt($slider_value, $new_slider_value, 'Slider has been updated by drag and drop to position');

done_testing;
