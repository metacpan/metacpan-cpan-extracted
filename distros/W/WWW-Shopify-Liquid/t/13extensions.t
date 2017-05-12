use strict;
use warnings;
use Test::More;
use utf8;
use DateTime;
use JSON qw(decode_json);
# Test bed for unary operators.
use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
use_ok("WWW::Shopify::Liquid::Optimizer");
use_ok("WWW::Shopify::Liquid::Renderer");
my $liquid = WWW::Shopify::Liquid->new;


# my $ast = $liquid->parse_text(q({% filter "TestFilter", 0, 0 %}
		# {% assign return = 1 %}
# {% endfilter %}{{ "Asdasd" | TestFilter }}));

# ok($ast);

done_testing();