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

my $text = $liquid->render_text({
	a => {
		b => WWW::Shopify::Liquid::Resolver->new(sub {
			return {
				d => 10
			}
		})
	}
}, "{{ a.b.c.d }}");
is($text, 10);

$text = $liquid->render_text({
	a => {
		b => WWW::Shopify::Liquid::Resolver->new(sub {
			my ($self, $hash, $name) = @_;
			return $name;
		})
	}
}, "{{ a.b.c }}");
is($text, 'c');

$text = $liquid->render_text({ }, "{{ now | date: '%Y' }}");
like($text, qr/^\d+$/);

done_testing();