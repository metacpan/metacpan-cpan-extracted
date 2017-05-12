# Using this method one translate an entire page 
# from phonetic to Indic language given.
use Unicode::Indic::Translate;
use strict;
my $tr = Unicode::Indic::Translate->new(
	InFile => $ARGV[0],
	OutFile => "t.$ARGV[0]",
	FromLang => $ARGV[1],
	ToLang => $ARGV[2],
);

$tr->translate();
