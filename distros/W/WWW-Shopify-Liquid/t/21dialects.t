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
use_ok("WWW::Shopify::Liquid::Debugger");
use_ok("WWW::Shopify::Liquid::Dialect::Web");
use_ok("WWW::Shopify::Liquid::Dialect::Shopify");

ok(1);

my $liquid = WWW::Shopify::Liquid->new;

my $text = eval { $liquid->render_text({ }, "{{ '\"' | escape_html }}"); };
ok($@);
ok(!$text);

$liquid = WWW::Shopify::Liquid->new(
	dialects => [WWW::Shopify::Liquid::Dialect::Web->new]
);
ok($liquid);
$text = eval { $liquid->render_text({ }, "{{ '\"' | escape_html }}"); };
ok(!$@);
is($text, '&quot;');

$liquid = WWW::Shopify::Liquid->new(
	dialects => [WWW::Shopify::Liquid::Dialect::Shopify->new]
);
ok($liquid);
$text = eval { $liquid->render_text({ }, "{{ '\"' | escape_html }}"); };
ok(!$@);
is($text, '&quot;');

done_testing();