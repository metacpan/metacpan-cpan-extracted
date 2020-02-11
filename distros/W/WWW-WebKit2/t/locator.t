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

$webkit->open("$Bin/test/locator.html");
ok(1, 'opened');

my $xpath_length = $webkit->resolve_locator("xpath=//option")->get_length;
is($xpath_length, "2", "got correct length with xpath");

my $option = $webkit->resolve_locator("label=Testoption")->get_tag_name;
is($option, "OPTION", "label resolved");

my $link = $webkit->resolve_locator("link=Testlink")->get_tag_name;
is($link, "A", "link resolved");

my $value = $webkit->resolve_locator("value=Testvalue2")->get_tag_name;
is($value, "OPTION", "value resolved");

my $index = $webkit->resolve_locator("index=1")->get_tag_name;
is($index, "OPTION", "index resolved");

my $id = $webkit->resolve_locator("id=content")->get_tag_name;
is($id, "DIV", "id resolved");

my $id_html = $webkit->resolve_locator("id=content")->get_inner_html;
is($id_html, "This is a <strong>very</strong> interesting text.", "id resolved");

my $id_text = $webkit->resolve_locator("id=content")->get_text;
is($id_text, "This is a very interesting text.", "id text resolved");

my $css = $webkit->resolve_locator("css=#content")->get_tag_name;
is($css, "DIV", "id resolved");

my $css_text = $webkit->resolve_locator("css=#content")->get_text;
is($css_text, "This is a very interesting text.", "got text with css");

my $css_html = $webkit->resolve_locator("css=#content")->get_inner_html;
is($css_html, "This is a <strong>very</strong> interesting text.", "got html with css");

my $css_attribute = $webkit->resolve_locator("css=#content")->get_attribute('data-type');
is($css_attribute, "blogpost", "got attribute with css");

my $css_length = $webkit->resolve_locator("css=select option")->get_length;
is($css_length, "2", "got correct length with css");

my $class = $webkit->resolve_locator("class=todo_list")->get_text;
like($class, qr/Urgent task/m, "class resolved");

my $name = $webkit->resolve_locator("name=username")->get_attribute('value');
is($name, "foobar", "name resolved");

ok($webkit->is_visible('xpath=//div[\@id="content"]'), "#content is visible");

eval { $webkit->is_visible('xpath=//div[\@id="foobar"]') };
like($@, qr/element not found/m, "is_visible croaks for inexistent elements");
ok($webkit->is_visible("css=.visible"), "span is visible");
ok(not($webkit->is_visible("css=.invisible")), "span is invisible");

is($webkit->resolve_locator("css=.positioned")->get_offset_width, 75, "offset width ok");
is($webkit->resolve_locator("css=.positioned")->get_offset_height, 50, "offset height ok");

# test single quotes within locator string
ok ($webkit->resolve_locator("css=body input[name='username']")->get_tag_name);
ok ($webkit->resolve_locator("//input[\@name='username']")->get_tag_name);

#test set_inner_text
ok($webkit->resolve_locator("css=.visible")->set_inner_text('perl is amazing'), 'set inner text method returned true');
is($webkit->resolve_locator("css=.visible")->get_text, 'perl is amazing', 'Set inner text set the text correctly');

done_testing;
