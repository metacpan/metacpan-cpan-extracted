#!perl -w

# Test for macro::compiler::_has_args():
#   It is not a public API,
#   but it requires many tests, because of its complexity.

use strict;
use Test::More;

use macro::compiler;
use PPI::Lexer;

our $Lexer = PPI::Lexer->new();

sub has_args{
	my($src) = @_;

	my $document = $Lexer->lex_source($src);

	# macro::compiler::_has_args() is called in _want_use_macro()
	my $result = $document->find_any(\&macro::compiler::_want_use_macro);
	if($@){
		die $@;
	}
	return $result;
}

my @true_cases = (
	'foo',
	q("foo"),
	q('foo'),
	q(qq(foo)),
	q(qq/foo/),
	q(q(foo)),
	q(q/foo/),

	'+foo',
	'+"foo"',
	'(foo)',
	'+(foo)',
	'(+foo)',
	'(+(foo))',
	'( + (+ foo ) )',
	'((), foo)',

	'qw(foo)',
	'qw/foo/',
	'+ qw(foo)',
	'(qw(foo))',
	'1.0 foo',
	'1.0 +foo',
	'1.0 (foo)',
	'1 foo',
	'1 qw(foo)',

	'((qw(foo)))',
	'(), foo',
	'(()), foo',
	'+(), foo',
	'+(()), foo',
	'+(+(+())),foo',
	"+(+(+())),\n\tfoo",

	"\n\tfoo",
	"\n=pod\n\n=cut\n\tfoo",
);

my @false_cases = (
	'',
	' ',
	"\n=pod\n\n=cut\n",
	'1.0',
	'1',
	'1.0.0',
	'()',
	'( )',
	'+()',
	'+( )',
	'(())',
	"+ ( + (\n) )",
	'qw()',
	'qw( )',
	"qw( \n )",
	'+ qw( )',
	'(),(),()',
	'+(), +(), +()',

	'1.0 ()',
	'1.0 (), +()',
	'1.0 (), (), ()',
);

plan tests => (scalar(@true_cases) + scalar(@false_cases) + 2);

for my $arg (@true_cases){
	my $case = "use macro $arg => sub{};";
	(my $msg = $case) =~ s/\n/\\n/msxg;

	ok has_args($case), 'T: ' . $msg;
}
for my $arg (@false_cases){
	my $case = "use macro $arg;";
	(my $msg = $case) =~ s/\n/\\n/msxg;

	ok !has_args($case), 'F: ' . $msg;
}

# special cases: no semicolon
ok  has_args('use macro foo => sub{}'), 'T: no semicolon with arguments';
ok !has_args('use macro ()'),           'F: no semicolon without arguments';
