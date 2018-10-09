use strict;
use warnings;
use Test::More;
use utf8;
use DateTime;
use JSON qw(decode_json);

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
use_ok("WWW::Shopify::Liquid::Optimizer");
use_ok("WWW::Shopify::Liquid::Renderer");
my $liquid = WWW::Shopify::Liquid->new;
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;
my $optimizer = $liquid->optimizer;
my $renderer = $liquid->renderer;


use WWW::Shopify::Liquid qw(liquid_render_text);

my $text = liquid_render_text({ a => "1234567890" }, "{{ a | truncate: 5 }}"); is($text, '12345');

$text = liquid_render_text({ a => "1234.56789" }, "{{ \"%.0d\" | sprintf: a }}"); is($text, '1234');

$text = liquid_render_text({ order => {
	total_discounts => 10,
	total_line_items_price => 10,
	total_shipping => 10
} }, '{% assign discount_percent = ((order.total_discounts / (order.total_line_items_price+order.total_shipping)) * 100) %}{{ "%.0f" | sprintf: discount_percent }}');
is($text, 50);

$text = liquid_render_text({ a => "會" }, "{% if a | is_utf8 %}1{% else %}0{% endif %}"); is($text, '1');
$text = liquid_render_text({ a => "a" }, "{% if a | is_utf8 %}1{% else %}0{% endif %}"); is($text, '0');

my $dt = DateTime->now;
$text = liquid_render_text({ a => { b => 2, cc => [$dt] } }, "{{ a | json }}");
my $j = eval { decode_json($text); };
is($@, '');
ok($j);
isa_ok($j, 'HASH');
is($j->{b}, 2);
isa_ok($j->{cc}, 'ARRAY');
is($j->{cc}->[0], $dt->iso8601);

$text = liquid_render_text({ a => "February 10th, 1989" }, "{{ a | date_parse }}");
is($text, DateTime->new(year => 1989, month => 2, day => 10)->iso8601);

$text = liquid_render_text({ a => "2015-01-01T00:00:00 EST5EDT" }, "{{ a | date_parse }}");

$text = liquid_render_text({ a => "" }, "{{ '08/28/15' | date_parse | date: '%Y' }}");

$text = liquid_render_text({ a => "2015-01-01T00:00:00 EST5EDT" }, "{{ a | date_parse | date_set_time_zone: 'GMT' }}");
is($text, DateTime->new(year => 2015, month => 1, day => 1, hour=>5, minute=>0, second=>0, time_zone => 'GMT')->iso8601);


$text = liquid_render_text({ a => 10.43545 }, "{{ a | round }}");
is($text, 10);
$text = liquid_render_text({ a => 10.43545 }, "{{ a | round: 0 }}");
is($text, 10);
$text = liquid_render_text({ a => 10.43545 }, "{{ a | round: 1 }}");
is($text, 10.4);
$text = liquid_render_text({ a => 10.43545 }, "{{ a | round: 2 }}");
is($text, 10.44);

done_testing();
