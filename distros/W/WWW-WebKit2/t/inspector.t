use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Test::More;
use lib 'lib';
use FindBin qw($Bin $RealBin);
use File::Slurper qw(read_text);
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

$webkit->open("$Bin/test/locator.html");
ok(1, 'opened');

# test function object return for run_javascript_finish
eval {
    $webkit->eval_js(<<"JS");
       var foo = function() {};
       retun foo.bar = function() {};
JS
};
like $@, qr/Unexpected return value/, 'eval_js dies with more useful error message';

my $js = $webkit->run_javascript('return document.title');
is($js, 'test', 'document.title is test');

my $html_source = $webkit->get_html_source();
like($html_source, qr/head\>\n.+/, 'HTML source is there');

my $title = $webkit->get_title();
is ($title, 'test', 'Get title returned test');

my $body = $webkit->get_body_text();
like ($body, qr/This is a very interesting text/, 'Get body text returned test_body');

my $text = $webkit->get_text('xpath=//a');
is($text, "Testlink", "get_text works");

my $evaluated_js = $webkit->eval_js(
    'document.body.style.height = "400px";
    return document.body.offsetHeight'
);
ok($evaluated_js == 400, "we can calculated with returned value");
is($evaluated_js, 400, "eval_js works");

my $xpath_count = $webkit->get_xpath_count('//div');
is($xpath_count, 1, "one <div> found");

my $value = $webkit->get_value('xpath=//input[@name="age"]');
is($value, "30", "get_value works");

my $css_value = $webkit->get_value('css=input[name=age]');
is($css_value, "30", "get_value works with css");

my $attribute = $webkit->get_attribute('xpath=//input[@name="age"]@value');
is($attribute, "30", "get_attribute with \@value works");

my $attribute_id = $webkit->get_attribute('css=#content@id');
is($attribute_id, "content", "get_attribute with \@id works");

ok($webkit->is_element_present('css=#content'), 'css content is present');
ok($webkit->is_element_present('xpath=//div[@id="content"]'), 'xpath content is present');
ok(not($webkit->is_element_present('css=#foobar')), '#foobar is not present');
ok(not($webkit->is_element_present('xpath=//div[@id="foobar"]')), 'xpath #foobar is not present');
ok((not $webkit->is_element_present('css=input')), 'false on multiple css matches');
ok((not $webkit->is_element_present('//input')), 'false on multiple xpath matches');
ok((not $webkit->is_element_present('css=definitely_nothing')), 'false on 0 css matches');
ok((not $webkit->is_element_present('//definitely_nothing')), 'false on 0 xpath matches');

ok($webkit->is_ordered('css=head', 'css=body'), 'head > body order correct');
ok($webkit->is_ordered('css=#content', 'css=form'), 'order correct');
ok(not($webkit->is_ordered('css=form', 'css=#content')), 'order not correct');
ok($webkit->is_ordered('xpath=//div[@id="content"]', 'xpath=//form'), 'order correct');
ok(not($webkit->is_ordered('xpath=//form', 'xpath=//div[@id="content"]')), 'order not correct');

ok($webkit->check_window_bounds(0, 10, 'window test'));
eval { $webkit->check_window_bounds(10000, 100000, 'window too big') };
like($@, qr/out of bounds/m, "check_window_bounds croaks when window isn't big enough");

my @position = $webkit->get_screen_position("css=.positioned");
is($position[0], 100, "screen position x ok");
is($position[1], 100, "screen position y ok");

my @center_position = $webkit->get_center_screen_position("css=.positioned");
is($center_position[0], 137.5, "center screen position x ok");
is($center_position[1], 125, "center screen position y ok");

ok($webkit->disable_plugins, "disabled plugins");
ok($webkit->enable_plugins, "enabled plugins");
ok($webkit->enable_hardware_acceleration, "enabled hardware acceleration");

$webkit->run_javascript('window.print()');
ok($webkit->print_requested, 'print popped up');

$webkit->run_javascript('confirm("Confirm?")');
is($webkit->get_confirmation, 'Confirm?', 'confirmation popped up');

$webkit->run_javascript('alert("Alert!")');
is($webkit->get_alert, 'Alert!', 'alert popped up');

$webkit->enable_console_log;
$webkit->open("$Bin/test/console_error.html");
$webkit->run_javascript('console.log("console log stdout test")');

$webkit->open("$Bin/test/unload.html");
ok($webkit->type_keys("name=test_text", 'testing refresh prompt'), 'text entered to encourage dialog prompt was successful');
$webkit->open("$Bin/test/console_error.html");
#see: https://developer.mozilla.org/en-US/docs/Web/Events/beforeunload$
is($webkit->get_confirmation, "It should be Dialogue not dialog.", 'The dialogue box returned the custom message on unload');

# test get_html_source
$webkit->open("$Bin/test/load.html");

is($webkit->get_html_source, read_text("$Bin/test/load.html"), 'got html source');

done_testing;
