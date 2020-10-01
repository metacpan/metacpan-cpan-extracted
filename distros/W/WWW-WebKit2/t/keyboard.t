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

$webkit->open("$Bin/test/keyboard.html");

my $text = 'test';
is($webkit->get_value('//input'), "1", "input value is 1");
$webkit->type('//input', $text);
is($webkit->get_value('//input'), $text, "input value is $text");

# make sure type can deal with line breaks, though get_value does not preserve them
$webkit->type('//input', "line1\nline2");
is($webkit->get_value('//input'), "line1 line2", "input value is correct");

$webkit->type('//input', 'this is a "test"');
is($webkit->get_value('//input'), 'this is a "test"', 'can type "');

$webkit->resolve_locator('//input')->set_value('');
$webkit->type_keys('//input', '1,5 Bar');
$webkit->wait_for_condition(sub {
    $webkit->get_value('//input') eq '1,5 Bar'
});

$webkit->resolve_locator('//input')->set_value('');
$webkit->type_keys('//input', "Foo Bar");
$webkit->wait_for_condition(sub {
    $webkit->get_value('//input') eq "Foo Bar"
});

$webkit->delete_text('css=#editable');

$webkit->open("$Bin/test/key_press.html");
$webkit->key_press('css=body', '\027');
$webkit->wait_for_alert;
is(pop @{ $webkit->alerts }, 27);
$webkit->key_press('css=body', '\013');
$webkit->wait_for_alert('13');
is(pop @{ $webkit->alerts }, 13);
$webkit->key_press('css=body', 'a');
$webkit->wait_for_alert('65');
is(pop @{ $webkit->alerts }, 65);
$webkit->key_press('css=body', '\032');
$webkit->wait_for_alert;
is(pop @{ $webkit->alerts }, 32);

my $default_confirm = $webkit->accept_confirm;
$webkit->accept_confirm(0);

$webkit->open("$Bin/test/confirm.html");
is($webkit->get_text('id=result'), 'no');
$webkit->accept_confirm($default_confirm);

$webkit->answer_on_next_confirm(1);
$webkit->open("$Bin/test/confirm.html");
is(pop @{ $webkit->confirmations }, 'test');
is($webkit->get_text('id=result'), 'yes');

$webkit->accept_confirm(1);
$webkit->open("$Bin/test/confirm.html");
is($webkit->get_text('id=result'), 'yes');
$webkit->accept_confirm($default_confirm);

$webkit->answer_on_next_confirm(0);
$webkit->open("$Bin/test/confirm.html");
is($webkit->get_text('id=result'), 'no');

$webkit->answer_on_next_prompt('test answer');
$webkit->open("$Bin/test/prompt.html");
is($webkit->get_text('id=result'), 'test answer');

done_testing;
