use strict;
use warnings;
use Test::More;
use utf8;

package WWW::Shopify::Liquid::Filter::Pause;
use base 'WWW::Shopify::Liquid::Filter';

sub operate {
	my ($self, $hash, $operand) = @_;
	die new WWW::Shopify::Liquid::Exception::Control::Pause($self, $hash, $operand);
}

package main;

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
$liquid->renderer->{silence_exceptions} = undef;
my $text;
my $exp;
$liquid->register_filter('WWW::Shopify::Liquid::Filter::Pause');

my $ast = $liquid->parse_text("
	A
	B
	C
	{{ a.b | pause }}
	{% for i in array %}
		{{ i }}
	{% endfor %}
	{{ i | pause }}
	Z
");

my @tokens = $ast->tokens;
is(int(@tokens), 20);

my ($pause) = grep { $_->isa('WWW::Shopify::Liquid::Filter::Pause') && $_->{line}->[0] == 5 } @tokens;
ok($pause);

eval {
	$text = $liquid->render_ast({ }, $ast);
};
$exp = $@;
ok($exp);
isa_ok($exp, 'WWW::Shopify::Liquid::Exception::Control::Pause');
# Should be exactly two values here, that of the pause, and that of the variable. Tokens are explicitly not included.
# In a pause, the only times that we need to actually break from the convention of simply applying variable reference is when we're inside
# A forloop. In that case, a global state variable should be kept denoting where in a forloop grouping we are.
# Everything else should be completely stackless. 
is(int(keys(%{$exp->{values}})), 1);
ok(exists $exp->{values}->{$pause});
eval {
	$text = $liquid->render_resume($exp, $ast);
};
$exp = $@;
ok($exp);
isa_ok($exp, 'WWW::Shopify::Liquid::Exception::Control::Pause');
# Should have 4 values here, one for output, one for forloop, one for pause.
is(int(keys(%{$exp->{values}})), 3);

eval {
	$text = $liquid->render_resume($exp, $ast);
};
$exp = $@;


$ast = $liquid->parse_text("
	A
	B
	C
	{% for i in array %}
		{{ i | pause }}
	{% endfor %}
	Z
");
ok($ast);
eval {
	$text = $liquid->render_ast({ }, $ast);
};
$exp = $@;
ok(!$exp);

$ast = $liquid->parse_text("
	A
	B
	C
	{% for i in array -%}
		{{ i | pause }}
	{%- endfor %}
	Z
");
ok($ast);
eval {
	$text = $liquid->render_ast({ array => [1,2,3] }, $ast);
};
$exp = $@;
ok($exp);
isa_ok($exp, 'WWW::Shopify::Liquid::Exception::Control::Pause');
# Should have 2 values here, one for forloop, one for pause.
is(int(keys(%{$exp->{values}})), 2);
eval {
	$text = $liquid->render_resume($exp, $ast);
};
$exp = $@;
ok($exp);

eval {
	$text = $liquid->render_resume($exp, $ast);
};
$exp = $@;
ok($exp);


eval {
	$text = $liquid->render_resume($exp, $ast);
};
$exp = $@;
ok(!$exp);

is($text, q(
	A
	B
	C
	123
	Z
));

done_testing();