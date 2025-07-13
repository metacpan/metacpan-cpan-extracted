use Test::More;
use autobox::Text;

$\ = "\n"; $, = "\t";

my $t = " stuff   and more ";

my @t = (
	 'stuff   and more',
	 'stuff and more'
	);


is ($t->trim, (shift @t), "trim");
is ($t->tidy, (shift @t), "tidy");

done_testing()
