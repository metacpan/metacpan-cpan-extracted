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

my $ast = $parser->parse_tokens($lexer->parse_text("{% for a in (1..10) %}\nsdfasdfds\n{% endfor %}"));
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::For');
isa_ok($ast->{contents}, 'WWW::Shopify::Liquid::Token::Text');
is($ast->{contents}->{line}->[0], 1);

done_testing();