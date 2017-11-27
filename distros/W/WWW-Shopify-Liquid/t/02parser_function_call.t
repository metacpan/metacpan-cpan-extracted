use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
my $liquid = WWW::Shopify::Liquid->new;
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;

my $ast;

my @tokens = $lexer->parse_text('{% assign abc = def.hij.klm("nop", "qrs") %}');

is(int(@tokens), 1);
$ast = $parser->parse_tokens(@tokens);

isa_ok($ast, 'WWW::Shopify::Liquid::Tag::Assign');
is(int(@{$ast->{arguments}}), 1);
is(int(@{$ast->{arguments}->[0]->{operands}}), 2);
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Operator::Assignment');
is($ast->{arguments}->[0]->{operands}->[0]->{core}->[0]->{core}, "abc");
isa_ok($ast->{arguments}->[0]->{operands}->[1], 'WWW::Shopify::Liquid::Token::FunctionCall');
isa_ok($ast->{arguments}->[0]->{operands}->[1]->{method}, 'WWW::Shopify::Liquid::Token::String');
is($ast->{arguments}->[0]->{operands}->[1]->{method}->{core}, 'klm');
isa_ok($ast->{arguments}->[0]->{operands}->[1]->{self}, 'WWW::Shopify::Liquid::Token::Variable');
is(int(@{$ast->{arguments}->[0]->{operands}->[1]->{arguments}}), 2);

done_testing();
