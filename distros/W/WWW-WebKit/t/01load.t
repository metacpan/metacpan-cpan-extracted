use strict;
use warnings;
use utf8;

use Test::More;
use FindBin qw($Bin);
use URI;

BEGIN {
    use_ok 'WWW::WebKit';
}

my $sel = WWW::WebKit->new(xvfb => 1);
eval { $sel->init; };
if ($@ and $@ =~ /\ACould not start Xvfb/) {
    $sel = WWW::WebKit->new();
    $sel->init;
}
elsif ($@) {
    diag($@);
    fail('init webkit');
}
ok(1, 'init done');

$sel->open("$Bin/test/load.html");
ok(1, 'opened');

is($sel->get_body_text, 'test');

$sel->open("$Bin/test/drag_and_drop.html");
ok(1, 'opened');

$sel->native_drag_and_drop_to_object('id=dragme', 'id=target');
is($sel->resolve_locator('id=dragme')->get_parent_node->Gtk3::WebKit::DOMElement::get_id, 'target');

$sel->refresh;

my $default_confirm = $sel->accept_confirm;
$sel->accept_confirm(0);

$sel->open("$Bin/test/confirm.html");
is($sel->get_text('id=result'), 'no');
$sel->accept_confirm($default_confirm);

$sel->answer_on_next_confirm(1);
$sel->open("$Bin/test/confirm.html");
is(pop @{ $sel->confirmations }, 'test');
is($sel->get_text('id=result'), 'yes');

$sel->accept_confirm(1);
$sel->open("$Bin/test/confirm.html");
is($sel->get_text('id=result'), 'yes');
$sel->accept_confirm($default_confirm);

$sel->answer_on_next_confirm(0);
$sel->open("$Bin/test/confirm.html");
is($sel->get_text('id=result'), 'no');

$sel->answer_on_next_prompt('test answer');
$sel->open("$Bin/test/prompt.html");
is($sel->get_text('id=result'), 'test answer');

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

$sel->open("$Bin/test/key_press.html");
$sel->key_press('css=body', '\027');
$sel->wait_for_alert;
is(pop @{ $sel->alerts }, 27);
$sel->key_press('css=body', '\013');
$sel->wait_for_alert('13');
is(pop @{ $sel->alerts }, 13);
$sel->key_press('css=body', 'a');
$sel->wait_for_alert('65');
is(pop @{ $sel->alerts }, 65);
$sel->key_press('css=body', '\032');
$sel->wait_for_alert;
is(pop @{ $sel->alerts }, 32);

$sel->open("$Bin/test/ordered.html");
ok($sel->is_ordered('id=first', 'id=second'), 'is_ordered is correct for ordered elements');
ok((not $sel->is_ordered('id=second', 'id=first')), 'is_ordered detects wrong order correctly');

$sel->open("$Bin/test/eval.html");
is($sel->eval_js('"foo"'), 'foo');
is($sel->eval_js('document.getElementById("foo").firstChild.data'), 'bar');

$sel->open("$Bin/test/type.html");
$sel->type('id=foo', 'bar');
$sel->click('id=submit');
$sel->wait_for_condition(sub {
    URI->new($sel->view->get_uri)->query eq 'foo=bar'
});

$sel->open("$Bin/test/type.html");
$sel->type_keys('id=foo', 'bar');
$sel->click('id=submit');
$sel->wait_for_condition(sub {
    URI->new($sel->view->get_uri)->query eq 'foo=bar'
});

$sel->open("$Bin/test/type.html");
$sel->type_keys('id=foo', '1,5 Bar');
$sel->click('id=submit');
$sel->wait_for_condition(sub {
    URI->new($sel->view->get_uri)->query eq 'foo=1%2C5+Bar'
});

$sel->open("$Bin/test/delete.html");
$sel->delete_text('id=foo');
$sel->delete_text('id=bar');
$sel->click('id=submit');
$sel->wait_for_condition(sub {
    URI->new($sel->view->get_uri)->query eq 'foo2=&bar2=&baz2=27+Baz'
});

$sel->open("$Bin/test/select.html");
$sel->select('id=test', 'value=1');
is(pop @{ $sel->alerts }, 'onchange fired');
$sel->select('id=test_event', 'value=1');
is(pop @{ $sel->alerts }, 'change event fired');

$sel->open("$Bin/test/utf8.html");
is($sel->resolve_locator('xpath=//*[text() = "föö"]')->Gtk3::WebKit::DOMElement::get_id, 'test');
ok($sel->is_element_present('xpath=//*[text() = "föö"]'));

$sel->disable_plugins;
ok(1, 'disable_plugins worked');

$sel->open("$Bin/test/load.html");
ok(1, 'loaded test page without plugins');

done_testing;
