use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");

my $lexer = WWW::Shopify::Liquid->new->lexer;

my @tokens = $lexer->parse_text("{% for i in (1..2) %}\n{{ i }}\n{% endfor %}");
is(int(@tokens), 5);
isa_ok($tokens[0], 'WWW::Shopify::Liquid::Token::Tag');
is($tokens[0]->{line}->[0], 1);
isa_ok($tokens[1], 'WWW::Shopify::Liquid::Token::Text');
is($tokens[1]->{line}->[0], 1);
isa_ok($tokens[2], 'WWW::Shopify::Liquid::Token::Output');
is($tokens[2]->{line}->[0], 2);
isa_ok($tokens[3], 'WWW::Shopify::Liquid::Token::Text');
is($tokens[3]->{line}->[0], 2);
isa_ok($tokens[4], 'WWW::Shopify::Liquid::Token::Tag');
is($tokens[4]->{line}->[0], 3);

@tokens = $lexer->parse_text("{% assign a = 1 | pluralize: 'asd', 'sadfsdf' %}");
is(int(@tokens), 1);
isa_ok($tokens[0], 'WWW::Shopify::Liquid::Token::Tag');
is(int(@{$tokens[0]->{arguments}}), 9);
isa_ok($tokens[0]->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable');
isa_ok($tokens[0]->{arguments}->[1], 'WWW::Shopify::Liquid::Token::Operator');
isa_ok($tokens[0]->{arguments}->[2], 'WWW::Shopify::Liquid::Token::Number');
isa_ok($tokens[0]->{arguments}->[3], 'WWW::Shopify::Liquid::Token::Operator');
isa_ok($tokens[0]->{arguments}->[4], 'WWW::Shopify::Liquid::Token::Variable');
isa_ok($tokens[0]->{arguments}->[5], 'WWW::Shopify::Liquid::Token::Separator');
isa_ok($tokens[0]->{arguments}->[6], 'WWW::Shopify::Liquid::Token::String');
isa_ok($tokens[0]->{arguments}->[7], 'WWW::Shopify::Liquid::Token::Separator');
isa_ok($tokens[0]->{arguments}->[8], 'WWW::Shopify::Liquid::Token::String');

done_testing();