use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
use_ok("WWW::Shopify::Liquid::Optimizer");
my $liquid = WWW::Shopify::Liquid->new;
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;
my $optimizer = $liquid->optimizer;

my $comment = "{% comment %}

sdlafkjskldfhlksadjfsd
{% endcomment %}asdfds";

my $ast = $parser->parse_tokens($lexer->parse_text($comment));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');
$ast = $optimizer->optimize({}, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Token::Text');
is($ast->{core}, 'asdfds');

done_testing();
