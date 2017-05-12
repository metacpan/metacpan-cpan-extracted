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
$optimizer->security(WWW::Shopify::Liquid::Security::Strict->new);
my $renderer = $liquid->renderer;
$renderer->security(WWW::Shopify::Liquid::Security::Strict->new);

my @tokens = $lexer->parse_text("{% for a in (1..2000) %}a{% endfor %}");
my $ast = $parser->parse_tokens(@tokens);

eval {
	$ast = $optimizer->optimize({}, $ast);	
};
my $exp = $@;
isa_ok($exp, 'WWW::Shopify::Liquid::Exception::Security');


#@tokens = $lexer->parse_text("{% assign groups = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' =~ '(.*){1,32000}[bc]' %}");
#$ast = $parser->parse_tokens(@tokens);
#$renderer->timeout(4);
#eval {
#	$ast = $renderer->render({}, $ast);
#};
#$exp = $@;
#isa_ok($exp, 'WWW::Shopify::Liquid::Exception::Timeout');
#use Data::Dumper;
#print STDERR Dumper($ast);


done_testing();