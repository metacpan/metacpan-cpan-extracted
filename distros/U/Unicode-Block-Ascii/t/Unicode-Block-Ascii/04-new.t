use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::Block::Ascii;

# Test.
eval {
	Unicode::Block::Ascii->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Unicode::Block::Ascii->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
my $obj = Unicode::Block::Ascii->new;
isa_ok($obj, 'Unicode::Block');
isa_ok($obj, 'Unicode::Block::Ascii');
