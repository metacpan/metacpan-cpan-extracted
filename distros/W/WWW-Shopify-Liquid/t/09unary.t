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
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;
my $optimizer = $liquid->optimizer;
my $renderer = $liquid->renderer;

my @tokens = $lexer->parse_text("{% if !a %}A{% else %}B{% endif %}");
is(int(@tokens), 5);

my $ast = $parser->parse_tokens(@tokens);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{true_path}, 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Operator::Not');
isa_ok($ast->{arguments}->[0]->{operands}->[0], 'WWW::Shopify::Liquid::Token::Variable');

my $text = $renderer->render({ a => 1 }, $ast);
is($text, 'B');

$text = $renderer->render({ a => 0 }, $ast);
is($text, 'A');


$text = $liquid->render_text({ a => 0, b => 3 }, "{% if b and !a %}A{% else %}B{% endif %}");
is($text, 'A');

done_testing();