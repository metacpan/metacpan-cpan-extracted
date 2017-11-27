use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
use_ok("WWW::Shopify::Liquid::Optimizer");
use_ok("WWW::Shopify::Liquid::Renderer");
use_ok("WWW::Shopify::Liquid::Debugger");

ok(1);

my $liquid = WWW::Shopify::Liquid->new;

my $text = $liquid->render_text({ }, q(
	{%- create_tag "Test", "free" -%}
		adfsdfsd
	{%- endcreate_tag -%}
	{%- Test -%}
));
is($text, 'adfsdfsd');

$text = undef;
eval {
	$text = $liquid->render_text({ }, q(
		{%- Test -%}
	));
};
my $exp = $@;
ok(!$text);
ok($exp);

$text = undef;
eval {
	$text = $liquid->render_text({ }, q(
		{%- create_tag "Test2" -%}
			adfsdfsd
		{%- endcreate_tag -%}
		{%- Test2 -%}
	));
};
$exp = $@;
ok(!$text);
ok($exp);


$liquid->parser->transient_custom_operations(0);
$text = $liquid->render_text({ }, q(
	{%- create_tag "Test", "free" -%}
		adfsdfsd
	{%- endcreate_tag -%}
	{%- Test -%}
));

is($text, 'adfsdfsd');
$text = $liquid->render_text({ }, q(
	{%- Test -%}
));
is($text, 'adfsdfsd');



$liquid->parser->transient_custom_operations(1);
$text = $liquid->render_text({ }, q(
	{%- create_tag "Test2", "free" -%}
		dddddd
	{%- endcreate_tag -%}
	{%- Test -%}
	{%- Test2 -%}
));
is($text, 'adfsdfsddddddd');

$text = undef;
eval {
	$text = $liquid->render_text({ }, q(
		{%- Test -%}
		{%- Test2 -%}
	));
};
ok(!$text);
ok($exp);

$text = $liquid->render_text({ }, q(
	{%- Test -%}
));
is($text, 'adfsdfsd');


$text = $liquid->render_text({ }, q(
	{%- create_filter "filter1" -%}
		{% return "tesdfasdf" %}
	{%- endcreate_filter -%}
	{{- a | filter1 -}}
));
is($text, "tesdfasdf");

$text = undef;
eval {
	$text = $liquid->render_text({ }, q(
		{%- create_tag "custom_tag2", "free" -%}
			{% custom_tag2 %}
		{%- endcreate_tag -%}
		{% custom_tag2 %}
	));
};
$exp = $@;
ok(!$text);
ok($exp);

$liquid->parser->transient_custom_operations(0);
$liquid->parse_text(q(
		{%- create_tag "custom_tag3", "free" -%}
			aaaaa
		{%- endcreate_tag -%}
));

$text = $liquid->render_text({ }, "{% custom_tag3 %}");
is($text, 'aaaaa');


$liquid->parser->transient_custom_operations(0);
$liquid->parse_text(q(
		{%- create_tag "custom_tag3" -%}
			aaaaa {{ contents }}
		{%- endcreate_tag -%}
));

$text = $liquid->render_text({ }, "{% custom_tag3  %}bbbb{% endcustom_tag3 %}");
is($text, 'aaaaa bbbb');


done_testing();