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

my @tokens = $lexer->parse_text(q({%- assign username = "John G. Chalmers-Smith" -%}
{%- if username and username.size > 10 -%}
  Wow, {{ username }}, you have a long name!
{% else -%}
  Hello there!
{%- endif -%}));
my $ast = $liquid->parser->parse_tokens(@tokens);
ok($ast);
my $text = $liquid->renderer->render({ }, $ast);

like($text, qr/\n/);

@tokens = $lexer->parse_text(q({%- assign username = "John G. Chalmers-Smith" -%}
{%- if username and username.size > 10 -%}
  Wow, {{ username }}, you have a long name!
{%- else -%}
  Hello there!
{%- endif -%}));
$ast = $liquid->parser->parse_tokens(@tokens);
ok($ast);
$text = $liquid->renderer->render({ }, $ast);

unlike($text, qr/\n/);


@tokens = $lexer->parse_text(q(   {{- a -}}    ));
is(int(@tokens), 1);

done_testing();