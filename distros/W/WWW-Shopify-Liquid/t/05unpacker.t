use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");use strict;
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


my $original_text = " {%if a.b%}asdfsdfdsaf{%else%} {%for a in (1..10)%}{{a}} fdsfds{%if b%}{{b}}{%else%}sfasdf{%endif%}{%endfor%}{%endif%}";
my @tokens = $lexer->parse_text($original_text);


my $ast = $parser->parse_tokens(@tokens);
ok($ast);
@tokens = $parser->unparse_tokens($ast);

my $text = $lexer->unparse_text(@tokens);
is($text, $original_text);

$ast = $liquid->parse_text("{% if customer.metafields[shop_namespace]['shared-secret'] %}1{% endif %}");
$ast = $liquid->optimizer->optimize({ shop_namespace => "A" }, $ast);
@tokens = $parser->unparse_tokens($ast);
$text = $lexer->unparse_text(@tokens);
is($text, "{%if customer.metafields.A.shared-secret%}1{%endif%}");

@tokens = $lexer->parse_text("{{ 'a' }}");
$text = $lexer->unparse_text(@tokens);
is($text, "{{'a'}}");


@tokens = $lexer->parse_text("{% capture signup_link %}<a class='registry-link' href='{{ proxy_url }}/signup' class='giftreggie-signup-show'>{{ b }}</a>{% endcapture %}{{ signup_link }}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ proxy_url => "A", b => 2 }, $ast);

@tokens = $parser->unparse_tokens($ast);
$text = $lexer->unparse_text(@tokens);
is($text, "{%capture signup_link%}<a class='registry-link' href='A/signup' class='giftreggie-signup-show'>2</a>{%endcapture%}<a class='registry-link' href='A/signup' class='giftreggie-signup-show'>2</a>");


$ast = $parser->parse_tokens($lexer->parse_text("{% assign input_format = 'YYYY/MM/DD' %}"));
$ast = $optimizer->optimize({ }, $ast);
$ast = $optimizer->optimize({ }, $ast);
@tokens = $parser->unparse_tokens($ast);
$text = $lexer->unparse_text(@tokens);
is($text, "{%assign input_format = 'YYYY/MM/DD'%}");

done_testing();