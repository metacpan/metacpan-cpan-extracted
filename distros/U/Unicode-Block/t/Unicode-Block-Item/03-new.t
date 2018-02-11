use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Unicode::Block::Item;

# Test.
eval {
	Unicode::Block::Item->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Unicode::Block::Item->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
eval {
	Unicode::Block::Item->new;
};
is($EVAL_ERROR, "Parameter 'hex' is required.\n",
	'Parameter \'hex\' is required.');
clean();

# Test.
eval {
	Unicode::Block::Item->new(
		'hex' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'hex' isn't hexadecimal number.\n",
	'Parameter \'hex\' isn\'t hexadecimal number.');
clean();

# Test.
my $obj = Unicode::Block::Item->new(
	'hex' => '0a',
);
isa_ok($obj, 'Unicode::Block::Item');

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => 'a',
);
isa_ok($obj, 'Unicode::Block::Item');

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => 'A',
);
isa_ok($obj, 'Unicode::Block::Item');
