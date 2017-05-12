use strict;
use warnings;
use Test::More;

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

my $text = $renderer->render({}, $optimizer->optimize({}, $parser->parse_tokens($lexer->parse_text("{% for a in (1..10) %}{{ a.b }}{% endfor %}"))));
is($text, '');
$text = $renderer->render({}, $optimizer->optimize({}, $parser->parse_tokens($lexer->parse_text("{% for a in (1..10) %}{{ a }}{% endfor %}"))));
is($text, '12345678910');
$text = $renderer->render({}, $parser->parse_tokens($lexer->parse_text("{% for a in (1..10) %}{{ a }}{% endfor %}")));
is($text, '12345678910');

$text = $renderer->render({ b => [{ b => 1 }, { b => 7 }] }, $optimizer->optimize({}, $parser->parse_tokens($lexer->parse_text("{% for a in b %}{{ a.b }}{% else %}B{% endfor %}"))));
is($text, '17');
$text = $renderer->render({ b => [] }, $optimizer->optimize({}, $parser->parse_tokens($lexer->parse_text("{% for a in b %}{{ a.b }}{% else %}B{% endfor %}"))));
is($text, 'B');


use WWW::Shopify::Liquid qw(liquid_render_text);
my $email = "Hi {% if customer %}{{ customer.first_name }} {{ customer.last_name }}{%else%}Unknown Customer{%endif %}!";
$text = liquid_render_text({ customer => { first_name => "Adam", last_name => "Harrison" } }, $email);
is($text, "Hi Adam Harrison!");
$text = liquid_render_text({}, $email);
is($text, "Hi Unknown Customer!");

$text = liquid_render_text({ test => "asd" }, "{% case test %}{% when 'a' %}dafsd{% when 'b' %}{%else %}hghgh{% endcase %}"); is($text, 'hghgh');
$text = liquid_render_text({ test => "a" }, "{% case test %}{% when 'a' %}dafsd{% when 'b' %}{%else %}hghgh{% endcase %}"); is($text, 'dafsd');


$text = liquid_render_text({ test => "a" }, "{% assign test = 2 %}{{ test }}"); is($text, '2');

$text = liquid_render_text({ test => "a" }, "{% for a in (1..10) %}{% case a %} {% when 10 %}A {% when 1 %}B{% else %}C{% endcase %}{% endfor %}"); is($text, 'BCCCCCCCCA ');


$text = liquid_render_text({ files => [{ extension => "pdf" }, { extension => "wrd" }, { extension => "png" }] }, "{% for file in files %}{{ file.extension }}{% endfor %}");
is($text, 'pdfwrdpng');

$text = liquid_render_text({ instructions => "" }, "{% if instructions %}A{% else %}B{% endif %}"); is($text, 'B');

$text = liquid_render_text({ duration => "3 months" }, "{{ duration | split: ' ' | first }}"); is($text, '3');

$text = liquid_render_text({ 
	global => { customer_address => { 1234 => 'asd' } }, 
	customer => { id => 1234 } 
}, '{{ global.customer_address[customer.id] }}');
is($text, 'asd');

$text = liquid_render_text({ test_array => [{ src => "asdasf" }, { src => "dfhdfh" }, { src => "5135" }] }, "{{ test_array[1].src }}"); is($text, 'dfhdfh');
$text = liquid_render_text({ test_array => 0 }, "{% if test_array == 0 %}a{% else %}b{% endif %}"); is($text, 'a');

$text = liquid_render_text({}, "{% for a in (1..9) %}{% if a == 1 %}{{ a }}{% endif %}{% endfor %}"); is($text, '1');
$text = liquid_render_text({}, "{% for a in (1..9) %}{{ forloop.index0 }}{% endfor %}"); is($text, '012345678');
$text = liquid_render_text({}, "{% for a in (1..9) %}{{ forloop.index }}{% endfor %}"); is($text, '123456789');
$text = liquid_render_text({}, "{% for a in (1..9) %}{% if forloop.first %}1{% endif %}{% endfor %}"); is($text, '1');
$text = liquid_render_text({}, "{% for a in (1..9) %}{% unless a == 1 %}{{ a }}{% endunless %}{% endfor %}"); is($text, '23456789');
$text = liquid_render_text({}, "{% for a in (1..9) %}{% unless forloop.first %}{{ a }}{% endunless %}{% endfor %}"); is($text, '23456789');

$text = liquid_render_text({}, "{% capture name %}asdfsdf{% endcapture %}{{ name }}"); is($text, 'asdfsdf');

# This failed with an elsif, but works with an else.
my $template = "{{ line_item.sku }}{% for prop in line_item.properties %}{% if prop.name contains 'Size'%}{% if prop.value == 'Small/Medium' %}S{% elsif prop.value == 'Medium/Large' %}L{% endif %}{% endif %}{% endfor %}";
$text = liquid_render_text({ line_item => { sku => "A", properties => [{ name => 'Dog 1 Size', value => "Small/Medium" }] }}, $template); is($text, 'AS');
$text = liquid_render_text({ line_item => { sku => "A", properties => [{ name => 'Dog 1 Size', value => "Medium/Large" }] }}, $template); is($text, 'AL');

use DateTime;
my $now = DateTime->now;
$text = liquid_render_text({ now => $now }, "{{ now | date_math: 3, 'days' }}"); is($text, $now->clone->add(days => 3)->iso8601);

$text = liquid_render_text({ now => $now }, "{% if now < now | date_math: 3, 'days' %}ASD{% endif %}"); is($text, 'ASD');
$text = liquid_render_text({ now => $now }, "{% if now < now  %}ASD{% endif %}"); is($text, '');

$text = liquid_render_text({ now => $now }, "{% if now < now | date_math: -3, 'days' %}ASD{% endif %}"); is($text, '');

my $hash; 
eval { require 'WWW/Shopify.pm'; };
use DateTime;
if (!$@) {
	print STDERR "Performing Shopify Test...\n";
	($text, $hash) = liquid_render_text({ product => WWW::Shopify::Model::Product->new({ id => 1, variants => [WWW::Shopify::Model::Product::Variant->new({ inventory_quantity => 100 })] }) }, '{{ product.id }}');
	is($text, 1);
	
	
	my $order = WWW::Shopify::Model::Order->new({
		fulfillments => [WWW::Shopify::Model::Order::Fulfillment->new({
			created_at => DateTime->now
		})]
	});
	$order = $liquid->liquify_item($order);
	ok($order->{fulfillments}->[0]->{created_at});
	isa_ok($order->{fulfillments}->[0]->{created_at}, 'DateTime');
}

use File::Slurp;
use File::Spec;
my $tmpdir = File::Spec->tmpdir;
ok($tmpdir);
my $path = $tmpdir . "/test-include-file.liquid";
unlink($path) if -e $path;
$text = $liquid->render_ast({ },$liquid->parse_text("A{% include 'test-include-file' %}C")); is($text, "AC");
$liquid->renderer->inclusion_context($tmpdir);
$text = $liquid->render_ast({ },$liquid->parse_text("A{% include 'test-include-file' %}C")); is($text, "AC");
write_file($path, "{% assign b = 1 %}{{ b }}");
$text = $liquid->render_ast({ },$liquid->parse_text("A{% include 'test-include-file' %}C")); is($text, "A1C");
write_file($path, "D{% include 'test-include-file' %}F");
$text = $liquid->render_ast({ },$liquid->parse_text("A{% include 'test-include-file' %}C")); is($text, "ADDDDDDFFFFFFC");

done_testing();