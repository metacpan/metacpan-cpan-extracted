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

$ast = $parser->parse_tokens($lexer->parse_text('Hi{% if customer %}{{ customer.first_name }} {{ customer.lastname }}{% else %} a{%endif%}!'));


isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{operands}->[0], 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{operands}->[1], 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{operands}->[1]->{true_path}, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{operands}->[1]->{true_path}->{operands}->[0], 'WWW::Shopify::Liquid::Tag::Output');
isa_ok($ast->{operands}->[1]->{true_path}->{operands}->[1], 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{operands}->[1]->{true_path}->{operands}->[2], 'WWW::Shopify::Liquid::Tag::Output');
isa_ok($ast->{operands}->[1]->{false_path}, 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{operands}->[2], 'WWW::Shopify::Liquid::Token::Text');

$ast = $parser->parse_tokens($lexer->parse_text('{% case collection.handle %}{% when "test1" %}sadfh{% when "test2" %}saldkfjlk{% else %}asdfsdf{{ a }}dfdasd{% endcase %}'));
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::Case');
isa_ok($ast->{paths}->{test1}, 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{paths}->{test2}, 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{else}, 'WWW::Shopify::Liquid::Operator::Concatenate');

$ast = $parser->parse_tokens($lexer->parse_text('{% if template ==\'page.blank\' or template contains \'blog\' or template contains \'article\' %}
	{{ content_for_layout }}
{% else %}
	{% include "snippet-landing" %}
{% endif %}'));
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Operator::Or');
isa_ok($ast->{arguments}->[0]->{operands}->[0], 'WWW::Shopify::Liquid::Operator::Or');
isa_ok($ast->{arguments}->[0]->{operands}->[0]->{operands}->[0], 'WWW::Shopify::Liquid::Operator::Equals');
isa_ok($ast->{arguments}->[0]->{operands}->[0]->{operands}->[1], 'WWW::Shopify::Liquid::Operator::Contains');
isa_ok($ast->{arguments}->[0]->{operands}->[1], 'WWW::Shopify::Liquid::Operator::Contains');

	
done_testing();