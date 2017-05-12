#!perl -w

# PPI Document Dumper
# $ ppidump.pl -e 'print "Hello, world!\n"'
# $ ppidump.pl foo.pl

use strict;
use PPI::Lexer;
use PPI::Tokenizer;
use PPI::Dumper;

use Getopt::Long;

GetOptions(
	'locations' => \my $locations,
	'comments'  => \my $comments,
	'whitespace'=> \my $whitespace,
	'all'       => \my $all,
	'e=s'       => \my $eval_string,
) or exit(1);

if($all){
	$locations = $comments = $whitespace = 1;
}


my $tokenizer;

eval{
	if($eval_string){
		shift @ARGV;
		$tokenizer = PPI::Tokenizer->new(\$eval_string);
	}
	else{
		$tokenizer = PPI::Tokenizer->new(@ARGV);
	}
};

if($@){
	die $@->message, "\n";
}

unless(ref $tokenizer){
	die 'PPI::Tokanizer: ', $tokenizer, "\n";
}

my $document = PPI::Lexer->new()->lex_tokenizer($tokenizer);

printf "$0 (PPI/$PPI::VERSION, Perl %vd)\n", $^V;

PPI::Dumper->new($document, 
	whitespace => $whitespace,
	comments   => $comments,
	locations  => $locations,
)->print();

# PPI::Document provides complete() method,
# but it doesn't work as of PPI version 1.204_01
if($document->find_any(\&_want_continuation)){
	print "# structure not completed\n";
}

sub _want_continuation{
	my($document, $element) = @_;

	return $element->isa('PPI::Structure')
		&& !($element->start && $element->finish);
}
