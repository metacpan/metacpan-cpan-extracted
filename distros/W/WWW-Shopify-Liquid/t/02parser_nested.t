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

$ast = $parser->parse_tokens($lexer->parse_text("{% for a in (1..10) %}{% case a %}{% when 10 %}A{% when 1 %}B{% else %}C{% endcase %}{% endfor %}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::For');
isa_ok($ast->{contents}, 'WWW::Shopify::Liquid::Tag::Case');
isa_ok($ast->{contents}->{paths}->{10}, 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{contents}->{paths}->{1}, 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{contents}->{else}, 'WWW::Shopify::Liquid::Token::Text');


$ast = $parser->parse_tokens($lexer->parse_text("{% if a %}{% if b %}fasdfd{% else %}sdafsdf{% endif %}{% else %}sdfsdf{% endif %}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{true_path}, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable');

eval {
	$ast = $parser->parse_tokens($lexer->parse_text("{% case a %} {% when 'b' %}gfgdfg{% else %}asdf{% endcase %}"));
};
ok(!$@, $@);
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::Case');

$ast = $parser->parse_tokens($lexer->parse_text("{% if template == 'index' %}
	{% if settings.fp_title.size > 0 %}
		{{ settings.fp_title }}
	{% else %}
		{{ shop.name }}
	{% endif %}
{% elsif template == '404' %}
	{{ settings.404_title }}
{% else %}
	{{ page_title }} &ndash; {{ shop.name }}
{% endif %}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{true_path}, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{true_path}->{operands}->[1], 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{false_path}, 'WWW::Shopify::Liquid::Tag::If');

$ast = $parser->parse_tokens($lexer->parse_text("{% if line_item.variant_title contains '/' %}{{ line_item.variant_title }}{% else %}{{ line_item.variant_title }}{% if order.line_items[loop_index+1] and order.line_items[loop_index+1].price == 0 %} / {{ order.line_items[loop_index+1].variant_title }}{% endif %}{% endif %}"));
$ast->verify;
ok($ast);


my @tokens = $lexer->parse_text("{% assign cards = db.cards.search({ name: \"asdasd\" }) %}");
$ast = $parser->parse_tokens(@tokens);
ok($ast);

@tokens = $lexer->parse_text("{% assign cards = db.cards.search({ name: (\"%\" + test + \"%\") }) %}");
$ast = $parser->parse_tokens(@tokens);
ok($ast);


@tokens = $lexer->parse_text('{% assign hash = { name: { "-like": ("%" + arguments[0] + "%") } } %}');
$ast = $parser->parse_tokens(@tokens);
ok($ast);




done_testing();
