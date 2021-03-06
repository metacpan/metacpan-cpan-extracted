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

my @tokens = $lexer->parse_text("{% assign a = [1, 3, 5, a.b] %}{{ a | join: ',' }}");
my $ast = $liquid->parse_tokens(@tokens);
ok($ast);

my ($text, $hash) = $liquid->render_ast({ a => { b => 6 } }, $ast);
is($text, '1,3,5,6');
isa_ok($hash->{a}, 'ARRAY');
is($hash->{a}->[0], 1);
is($hash->{a}->[1], 3);
is($hash->{a}->[2], 5);
is($hash->{a}->[3], 6);

@tokens = $lexer->parse_text("{% assign a = [
	1,
	3,
	5,
	a.b
] %}{{ a | join: ',' }}");
$ast = $liquid->parse_tokens(@tokens);
ok($ast);
($text, $hash) = $liquid->render_ast({ a => { b => 6 } }, $ast);
is($text, '1,3,5,6');

@tokens = $lexer->parse_text("{% assign a = {
	1: 5,
	3: 6,
	5: 7,
	c: 8,
	\"a.b\": 10
} %}");
$ast = $liquid->parse_tokens(@tokens);
ok($ast);
($text, $hash) = $liquid->render_ast({ }, $ast);
isa_ok($hash->{a}, 'HASH');
is($hash->{a}->{1}, 5);
is($hash->{a}->{3}, 6);
is($hash->{a}->{5}, 7);
is($hash->{a}->{"a.b"}, 10);
is($hash->{a}->{"c"}, 8);

@tokens = $lexer->parse_text(q({% assign h = {
	'r': ('a' | first)
} %}));
is(int(@tokens), 1);
is(int(@{$tokens[0]->{arguments}}), 3);
isa_ok($tokens[0]->{arguments}->[-1], 'WWW::Shopify::Liquid::Token::Hash');

$ast = $liquid->parse_tokens(@tokens);

ok($ast);
is(int(@{$ast->{arguments}->[0]->{operands}->[1]->{members}}), 2);
isa_ok($ast->{arguments}->[0]->{operands}->[1]->{members}->[1], 'WWW::Shopify::Liquid::Filter::First');


done_testing();