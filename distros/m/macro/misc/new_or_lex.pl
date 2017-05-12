#!perl

use strict;
use Benchmark qw(:all);

use PPI;

my $lexer = PPI::Lexer->new();

my $src;
my $these = {
	'PPI::D->new' => sub{
		my $d = PPI::Document->new(\$src);
	},

	'lex_tokanizer' => sub{
		my $tok = PPI::Tokenizer->new(\$src);
		my $d = $lexer->lex_tokenizer($tok);
	},
};

print "For tiny code\n";
$src = 'foo()';
cmpthese timethese 0 => $these;

print "\nFor large code\n";
$src = <<'SRC';
use strict;
sub sum{
	my $sum = 0;
	for my $value(@_){
		$sum += $value;
	}
	return $sum;
}

print sum(1, 2, 3, 4, 5), "\n";
SRC
cmpthese timethese 0 => $these;
