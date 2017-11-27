use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
use_ok("WWW::Shopify::Liquid::Optimizer");
use_ok("WWW::Shopify::Liquid::Renderer");
use_ok("WWW::Shopify::Liquid::Debugger");

ok(1);

my $liquid = WWW::Shopify::Liquid->new;

my $text = $liquid->render_text({
 a => "{% if b %}1{% else %}2{% endif %}",
 b => 3
}, q({{ a | eval }}));

is($text, 1);

$text = $liquid->render_text({
 a => "{% if b %}1{% else %}2{% endif %}",
 b => 0
}, q({{ a | eval }}));

is($text, 2);

done_testing();