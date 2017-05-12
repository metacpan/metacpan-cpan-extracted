use Test::More tests => 8;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Token;


#
# is_expression()
#

my @types_expr = qw(Number Literal);
my @types_noex = qw(Operator);

for my $type(@types_expr){
	my $token = XML::Parser::Lite::Tree::XPath::Token->new();
	$token->{type} = $type;
	ok($token->is_expression == 1);
}

for my $type(@types_noex){
	my $token = XML::Parser::Lite::Tree::XPath::Token->new();
	$token->{type} = $type;
	ok($token->is_expression == 0);
}

my $token = XML::Parser::Lite::Tree::XPath::Token->new();
$token->{type} = 'TypeIMadeUp';
my $warned = 0;
my $is_expression = undef;
eval {
	local $SIG{__WARN__} = sub { $warned = 1; };
	$is_expression = $token->is_expression;
};
ok($is_expression == 0);
is($warned, 1, "warned correctly");


#
# match
#

my $error = XML::Parser::Lite::Tree::XPath::Result->new();
$error->{type} = 'Error';
$error->{value} = 'TEST';

$token = XML::Parser::Lite::Tree::XPath::Token->new();
$token->{type} = 'FooBar';

my $test = $token->eval($error);

ok($test->{type} eq $error->{type});
ok($test->{value} eq $error->{value});


#
# unknown token type
#

my $context = XML::Parser::Lite::Tree::XPath::Result->new();
$context->{type} = 'Number';
$context->{value} = 1;

my $result = $token->eval($context);

ok($test->{type} eq 'Error');
