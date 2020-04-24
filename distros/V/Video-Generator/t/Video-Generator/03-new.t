use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 10;
use Test::NoWarnings;
use Video::Generator;

# Test.
eval {
	Video::Generator->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Video::Generator->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
eval {
	Video::Generator->new(
		'image_type' => 'xxx',
	);
};
is($EVAL_ERROR, "Image type 'xxx' doesn't supported.\n",
	"Image type 'xxx' doesn't supported.");
clean();

# Test.
eval {
	Video::Generator->new(
		'duration' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'duration' must be numeric value or numeric value ".
	"with time suffix.\n", "Parameter 'duration' must be numeric ".
	"value or numeric value with time suffix.");
clean();

# Test.
eval {
	Video::Generator->new(
		'duration' => 'xxx',
	);
};
is($EVAL_ERROR, "Parameter 'duration' must be numeric value or numeric value ".
	"with time suffix.\n", "Parameter 'duration' must be numeric ".
	"value or numeric value with time suffix.");
clean();

# Test.
eval {
	Video::Generator->new(
		'duration' => '10000x',
	);
};
is($EVAL_ERROR, "Parameter 'duration' must be numeric value or numeric value ".
	"with time suffix.\n", "Parameter 'duration' must be numeric ".
	"value or numeric value with time suffix.");
clean();

# Test.
eval {
	Video::Generator->new(
		'fps' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'fps' must be numeric value.\n",
	"Parameter 'fps' must be numeric value.");
clean();

# Test.
eval {
	Video::Generator->new(
		'fps' => 'xxx',
	);
};
is($EVAL_ERROR, "Parameter 'fps' must be numeric value.\n",
	"Parameter 'fps' must be numeric value.");
clean();

# Test.
my $obj = Video::Generator->new;
isa_ok($obj, 'Video::Generator');
