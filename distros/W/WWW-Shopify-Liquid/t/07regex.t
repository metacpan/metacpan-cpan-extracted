use strict;
use warnings;
use Test::More;
use utf8;

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


use WWW::Shopify::Liquid qw(liquid_render_text);

my $text = liquid_render_text({}, "{% assign test = ('asd' =~ '(a)') %}{{ test[0] }}"); is($text, 'a');
$text = liquid_render_text({}, "{% assign test = ('asd' =~ '(a)') %}{% if test %}1{% endif %}"); is($text, '1');
$text = liquid_render_text({}, "{% assign test = ('asd' =~ 'a') %}{% if test %}{{ test[0] }}{% endif %}"); is($text, '1');

my $ast = $parser->parse_tokens($lexer->parse_text("{% assign base = (line_item.sku =~ '^(\\w+)TOP') %}"));
ok($ast);

$ast = $parser->parse_tokens($lexer->parse_text("{{ test | replace: '(À|Á|Â|Ã|Ä|Å|Æ|Ç|È|É|Ê|Ë|Ì|Í|Î|Ï|Ð|Ñ|Ò|Ó|Ô|Õ|Ö|Ø|Ù|Ú|Û|Ü|Ý|Þ|ß|à|á|â|ã|ä|å|æ|ç|è|é|ê|ë|ì|í|î|ï|ð|ñ|ò|ó|ô|õ|ö|ø|ù|ú|û|ü|ý|þ|ÿ)', '' }}"));
ok($ast);
$text = $renderer->render({ test => "15 Rue du Belvédère" }, $ast);
is($text, "15 Rue du Belvdre");
$ast = $parser->parse_tokens($lexer->parse_text("{{ test | replace: '[ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ]', '' }}"));
ok($ast);
$text = $renderer->render({ test => "15 Rue du Belvédère" }, $ast);
is($text, "15 Rue du Belvdre");

done_testing();