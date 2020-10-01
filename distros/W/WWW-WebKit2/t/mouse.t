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
elsif ($@) {
    diag($@);
    fail('init webkit');
}

$webkit->open("$Bin/test/mouse_input.html");

ok(1, 'opened');
my $select_value = $webkit->resolve_locator('.//select[@name="dropdown_list"]')->property_search('selectedOptions[0].value');
is($select_value, 'Please select', 'Current select value is Please Select');
$webkit->select('.//select[@name="dropdown_list"]', './/option[@value="testtwo"]');
my $updated_select_value = $webkit->resolve_locator('.//select[@name="dropdown_list"]')->property_search('selectedOptions[0].value');
is($updated_select_value, 'testtwo', 'Test Two is the new selected value');

$webkit->select('css=#body .form select[name="dropdown_list"]', 'label=Testone');

my $radio_value = $webkit->resolve_locator('.//input[@id="radiotest_one"]')->property_search('checked');
ok((not $radio_value), 'Radio value is currently false');
$webkit->check('.//input[@id="radiotest_one"]');
$radio_value = $webkit->resolve_locator('.//input[@id="radiotest_one"]')->property_search('checked');
ok($radio_value, 'Radio is set to true');

$webkit->uncheck('.//input[@id="radiotest_one"]');
$radio_value = $webkit->resolve_locator('.//input[@id="radiotest_one"]')->property_search('checked');
ok((not $radio_value), 'Radio is now set to false');

# checkboxes with click
my $checkbox_value = $webkit->resolve_locator('.//input[@id="checkboxtest"]')->property_search('checked');
ok((not $checkbox_value), 'Radio value is currently false');
$webkit->click('.//input[@id="checkboxtest"]');
$checkbox_value = $webkit->resolve_locator('.//input[@id="checkboxtest"]')->property_search('checked');
ok($checkbox_value, 'checkbox is set to true');

$webkit->click('.//input[@id="checkboxtest"]');
$checkbox_value = $webkit->resolve_locator('.//input[@id="checkboxtest"]')->property_search('checked');
ok((not $checkbox_value), 'checkbox is now set to false');

$webkit->mouse_over('.//li[@id="test_item_one"]');
my $mouse_over_result = $webkit->resolve_locator('.//li[@id="test_item_new"]');
is($mouse_over_result->get_attribute('value'),'value_added' , 'mouse over worked as expected');

$webkit->mouse_down('//div[@id="mouse_down_test"]');
my $mouse_down_result = $webkit->resolve_locator('.//div[@id="mouse_down_test"]');
is($mouse_down_result->get_attribute('value'), 'mouse_is_pressed_down', 'pressing the mouse down updates the value');

$webkit->mouse_up('//div[@id="mouse_up_test"]');
my $mouse_up_result = $webkit->resolve_locator('.//div[@id="mouse_up_test"]');
is($mouse_up_result->get_attribute('value'), 'mouse_has_been_released', 'Mouse released updated value.');

$webkit->click('.//div[@id="click_test"]');
is($webkit->get_alert, 'Test Alert', 'Alert was triggered after button click');

$webkit->click('.//div[@id="click_test_out_of_sight"]');
is($webkit->get_alert, 'Found me!', 'Found element to click on after scrolling');

$webkit->click('id=invisible_1');
is($webkit->get_alert, 'Found invisible!', 'Clicked invisible element');

$webkit->double_click('id=double_click');
is($webkit->get_alert, 'Double clicked!', 'Double-clicked element');

# test Javascript checks
ok($webkit->resolve_locator('id=checkbox_js_check')->get_checked, 'detected js check');
is($webkit->get_value('id=checkbox_js_check'), 'on');

done_testing;
