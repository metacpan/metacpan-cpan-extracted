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

my $ast = $liquid->parse_text("{{ shop.metafields.language_codes[cart.attributes['language']] }}");
ok($ast);
my $text = $lexer->unparse_text($parser->unparse_tokens($ast));
is($text, '{{shop.metafields.language_codes[cart.attributes.language]}}');

done_testing();