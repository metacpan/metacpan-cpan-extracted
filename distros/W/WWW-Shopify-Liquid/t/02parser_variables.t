use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
my $liquid = WWW::Shopify::Liquid->new;
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;

my $ast;

$ast = $parser->parse_tokens($lexer->parse_text('{% comment named: (email + "asdsdfasdf") %} {% endcomment %}'));
is(int(@{$ast->{arguments}}), 1);
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable::Named');
is($ast->{arguments}->[0]->{name}, 'named');
isa_ok($ast->{arguments}->[0]->{core}, 'WWW::Shopify::Liquid::Operator::Plus');

$ast = $parser->parse_tokens($lexer->parse_text('{% comment named: [] %} {% endcomment %}'));
is(int(@{$ast->{arguments}}), 1);
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable::Named');
is($ast->{arguments}->[0]->{name}, 'named');

$ast = $parser->parse_tokens($lexer->parse_text('{% comment named:[{ attachment: ( form.resume.base64 | ceil )}]  %} {% endcomment %}'));
is(int(@{$ast->{arguments}}), 1);
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable::Named');
is($ast->{arguments}->[0]->{name}, 'named');
isa_ok($ast->{arguments}->[0]->{core}, 'WWW::Shopify::Liquid::Token::Array');
isa_ok($ast->{arguments}->[0]->{core}->{members}->[0], 'WWW::Shopify::Liquid::Token::Hash');

$ast = $parser->parse_tokens($lexer->parse_text('{% comment named: [{ type: \'text/csv\', name: \'Test.csv\', attachments: \'asd,dfgds,sdfs\' }] %} {% endcomment %}'));
is(int(@{$ast->{arguments}}), 1);
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable::Named');
is($ast->{arguments}->[0]->{name}, 'named');

$ast = $parser->parse_tokens($lexer->parse_text("{{ a.b }}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::Output');
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable');

$ast = $parser->parse_tokens($lexer->parse_text("{% assign a.b = 1 %}"));
ok($ast);

$ast = $parser->parse_tokens($lexer->parse_text("{% if global.total_orders > 1000 %}{% assign global.total_orders = 0 %}{% endif %}{% assign global.total_orders = global.total_orders + order.total_price %}"));
$liquid->verify_text("{% if global.total_orders > 1000 %}{% assign global.total_orders = 0 %}{% endif %}{% assign global.total_orders = global.total_orders + order.total_price %}");
ok($ast);

$ast = $parser->parse_tokens($lexer->parse_text("{% for note in order.note_attributes %}{% if note.name == 'Edition' %}{% assign notes = note | split: '\\n' %}{% for line in notes %}{% if line contains line_item.title %}{% assign parts = line | split: 'edition: ' %}{{ parts | last }}{% endif %}{% endfor %}{% endif %}{% endfor %}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::For');
isa_ok($ast->{contents}, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{contents}->{true_path}, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{contents}->{true_path}->{operands}->[0], 'WWW::Shopify::Liquid::Tag::Assign');

$ast = $parser->parse_tokens($lexer->parse_text('{% unless global.customer_address[customer.id] %}{% assign global.customer_address[customer.id] = json %}{% endunless %}'));
ok($ast);


use Data::Dumper;
$ast = $parser->parse_tokens($lexer->parse_text('{% assign json = customer.addresses | json %}{% unless global.customer_address[customer.id] %}{% assign global.customer_address[customer.id] = json %}{% endunless %}{% if global.customer_address[customer.id] != json %}{% assign global.customer_address[customer.id] = json %}1{% else %}0{% endif %}'));
ok($ast);

$ast = $parser->parse_tokens($lexer->parse_text("{% capture name %}asdfsdf{% endcapture %}{{ name }}"));
ok($ast);


$ast = $parser->parse_tokens($lexer->parse_text('
{% for line_item in order.line_items %}
	{% if line_item.variant_id %}
		{% assign product = line_item.product_id | escape %}
		{% assign should_hide = 1 %}
		{% for variant in product.variants %}
			{% if variant.inventory_quantity == null or variant.inventory_quantity > 0 %}
				{% assign should_hide = 0 %}
			{% endif %}
		{% endfor %}
	{% endif %} 
{% endfor %}
{% if should_hide %}
	{% assign updated_product = "Product" | escape %}
	{% assign updated_product.published_at = now %}
	{% assign updated_product = updated_product | escape %}
{% endif %}
'));
ok($ast);

$ast = $parser->parse_tokens($lexer->parse_text("{% assign color = 1 %}{% if color %}{{ variant['option' + color] }}{% endif %}"));

ok($ast);
ok($ast->{operands});
ok($ast->{operands}->[1]);
isa_ok($ast->{operands}->[1], 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{operands}->[1]->{true_path}, 'WWW::Shopify::Liquid::Tag::Output');
ok($ast->{operands}->[1]->{true_path}->{arguments});
isa_ok($ast->{operands}->[1]->{true_path}->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable');
is(int(@{$ast->{operands}->[1]->{true_path}->{arguments}->[0]->{core}}), 2);
isa_ok($ast->{operands}->[1]->{true_path}->{arguments}->[0]->{core}->[0], 'WWW::Shopify::Liquid::Token::String');
isa_ok($ast->{operands}->[1]->{true_path}->{arguments}->[0]->{core}->[1], 'WWW::Shopify::Liquid::Operator::Plus');

$ast = $parser->parse_tokens($lexer->parse_text("{% assign color = {} %}"));
isa_ok($ast->{arguments}->[0]->{operands}->[1], 'WWW::Shopify::Liquid::Token::Hash');
ok($ast);

$ast = $parser->parse_tokens($lexer->parse_text("{{ 'this.is.a.test' | max }}"));
ok($ast);
ok($ast->{arguments}->[0]);
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Filter::Max');
isa_ok($ast->{arguments}->[0]->{operand}, 'WWW::Shopify::Liquid::Token::String');
is($ast->{arguments}->[0]->{operand}->{core}, 'this.is.a.test');


$ast = $parser->parse_tokens($lexer->parse_text("{% assign a = null %}sdf"));
my ($render, $hash) = $liquid->render_ast({ }, $ast);
is($render, 'sdf');
ok(exists $hash->{a});
ok(!defined $hash->{a});

$ast = $parser->parse_tokens($lexer->parse_text("{% assign a = arsdsf %}"));
($render, $hash) = $liquid->render_ast({ }, $ast);
ok(exists $hash->{a});
ok(!defined $hash->{a});

done_testing();
