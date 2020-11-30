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

my $timeout = 1000;

my $sel= WWW::WebKit2->new(xvfb => 1);
eval { $sel->init; };
if ($@ and $@ =~ /\ACould not start Xvfb/) {
    $sel = WWW::WebKit2->new();
    $sel->init;
}
elsif ($@) {
    diag($@);
    fail('init webkit');
}
ok(1, 'init done');

$sel->open("$Bin/test/load.html");
ok(1, 'opened');

$sel->refresh;

$sel->open("$Bin/test/print.html");
ok($sel->print_requested, "print requested");
ok((not $sel->print_requested), "print isn't requested a second time");

$sel->open("$Bin/test/attribute.html");
is($sel->get_attribute('id=test@class'), 'foo bar');

is($sel->is_visible('id=test'), 1, 'test visible');
is($sel->is_visible('id=invisible'), 0, 'invisible');
is($sel->is_visible('id=invisible_child'), 0, 'child invisible');
is($sel->is_visible('id=void'), 0, 'display none');
is($sel->is_visible('id=void_child'), 0, 'child display none');

ok($sel->is_element_present('link=linktext'));
ok($sel->is_element_present('link=inner_linktext'));
is($sel->select('name=select', 'index=1'), 1);

is($sel->check('name=checkbox'), 1);
is($sel->get_attribute('name=checkbox@checked'), 'checked');

is($sel->uncheck('name=checkbox'), 1);
ok(not $sel->get_attribute('name=checkbox@checked'));

$sel->open("$Bin/test/ordered.html");
ok($sel->is_ordered('id=first', 'id=second'), 'is_ordered is correct for ordered elements');
ok((not $sel->is_ordered('id=second', 'id=first')), 'is_ordered detects wrong order correctly');

$sel->open("$Bin/test/eval.html");
is($sel->eval_js('return "foo"'), 'foo', 'string evaluated');
is($sel->eval_js('return document.getElementById("foo").firstChild.data'), 'bar', 'js evaluated');

$sel->refresh;
$sel->open("$Bin/test/type.html");
$sel->type('id=foo', 'bar');
ok($sel->click_and_wait('id=submitter', $timeout), 'clicked on submitter');

ok($sel->view->get_uri, 'got uri');
$sel->open("$Bin/test/type.html");

ok($sel->type_keys('id=foo', 'bar'), 'typed bar');
ok($sel->click_and_wait('id=submitter', $timeout), 'clicked on another submitter');

$sel->open("$Bin/test/type.html");
$sel->type_keys('id=foo', '1,5 Bar');
$sel->click_and_wait('id=submitter', $timeout);

$sel->open("$Bin/test/select.html");
$sel->select('id=test', 'value=1');

is(pop @{ $sel->alerts }, 'onchange fired');
$sel->select('id=test_event', 'value=1');
is(pop @{ $sel->alerts }, 'change event fired');

$sel->open("$Bin/test/utf8.html");
is($sel->resolve_locator('xpath=//*[text() = "föö"]')->get_id, 'test');
ok($sel->is_element_present('xpath=//*[text() = "föö"]'));

$sel->disable_plugins;
ok(1, 'disable_plugins worked');

$sel->open("$Bin/test/load.html");
ok(1, 'loaded test page without plugins');

done_testing;
