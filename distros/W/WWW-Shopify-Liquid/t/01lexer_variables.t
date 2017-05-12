use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");

my $lexer = WWW::Shopify::Liquid->new->lexer;

my @tokens = $lexer->parse_text('{{ product.handle }}');

is(int(@tokens), 1);
isa_ok($tokens[0], 'WWW::Shopify::Liquid::Token::Output');
is(int(@{$tokens[0]->{core}}), 1);
isa_ok($tokens[0]->{core}->[0], 'WWW::Shopify::Liquid::Token::Variable');
is(int(@{$tokens[0]->{core}->[0]->{core}}), 2);
isa_ok($tokens[0]->{core}->[0]->{core}->[0], 'WWW::Shopify::Liquid::Token::String');
isa_ok($tokens[0]->{core}->[0]->{core}->[1], 'WWW::Shopify::Liquid::Token::String');

@tokens = $lexer->parse_text("{{ customer['test']['b'] }}");

is(int(@tokens), 1);
isa_ok($tokens[0], 'WWW::Shopify::Liquid::Token::Output');
is(int(@{$tokens[0]->{core}}), 1);
isa_ok($tokens[0]->{core}->[0], 'WWW::Shopify::Liquid::Token::Variable');
is(int(@{$tokens[0]->{core}->[0]->{core}}), 3);
isa_ok($tokens[0]->{core}->[0]->{core}->[0], 'WWW::Shopify::Liquid::Token::String');
isa_ok($tokens[0]->{core}->[0]->{core}->[1], 'WWW::Shopify::Liquid::Token::String');
isa_ok($tokens[0]->{core}->[0]->{core}->[2], 'WWW::Shopify::Liquid::Token::String');


@tokens = $lexer->parse_text('{{ "\n" }}');
isa_ok($tokens[0], 'WWW::Shopify::Liquid::Token::Output');
is(int(@{$tokens[0]->{core}}), 1);
is($tokens[0]->{core}->[0]->{core}, "\n");

$lexer->parse_escaped_characters(0);

@tokens = $lexer->parse_text('{{ "\n" }}');
isa_ok($tokens[0], 'WWW::Shopify::Liquid::Token::Output');
is(int(@{$tokens[0]->{core}}), 1);
is($tokens[0]->{core}->[0]->{core}, '\n');

done_testing();