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

my $ast = $parser->parse_tokens($lexer->parse_text("{% for a in (1..20) %}{% assign a = 10 %}{{ a }}{% endfor %}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::For');
isa_ok($ast->{contents}, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{contents}->{operands}->[0], 'WWW::Shopify::Liquid::Tag::Assign');
isa_ok($ast->{contents}->{operands}->[1], 'WWW::Shopify::Liquid::Tag::Output');

$ast = $parser->parse_tokens($lexer->parse_text("{% include 'ast' %}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::Include');
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Token::String');
$ast = $parser->parse_tokens($lexer->parse_text("{% include 'ast' with 'ahlfjdkjg' %}"));
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::Include');
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Operator::With');
ok($ast);

ok(1);

done_testing();

