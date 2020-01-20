use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Image::Random;
use Test::More 'tests' => 14;
use Test::NoWarnings;
use Video::Pattern;

# Test.
eval {
	Video::Pattern->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Video::Pattern->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
eval {
	Video::Pattern->new(
		'duration' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'duration' must be numeric value or numeric value ".
	"with time suffix.\n", "Parameter 'duration' must be numeric ".
	"value or numeric value with time suffix.");
clean();

# Test.
eval {
	Video::Pattern->new(
		'duration' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'duration' must be numeric value or numeric value ".
	"with time suffix.\n", "Parameter 'duration' must be numeric ".
	"value or numeric value with time suffix.");
clean();

# Test.
eval {
	Video::Pattern->new(
		'duration' => '10000x',
	);
};
is($EVAL_ERROR, "Parameter 'duration' must be numeric value or numeric value ".
	"with time suffix.\n", "Parameter 'duration' must be numeric ".
	"value or numeric value with time suffix.");
clean();

# Test.
eval {
	Video::Pattern->new(
		'fps' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'fps' must be numeric value.\n",
	"Parameter 'fps' must be numeric value.");
clean();

# Test.
eval {
	Video::Pattern->new(
		'fps' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'fps' must be numeric value.\n",
	"Parameter 'fps' must be numeric value.");
clean();

# Test.
my $obj = Video::Pattern->new;
isa_ok($obj, 'Video::Pattern');

# Test.
$obj = Video::Pattern->new(
	'duration' => '1s',
);
is($obj->{'duration'}, 1000);
isa_ok($obj, 'Video::Pattern');

# Test.
$obj = Video::Pattern->new(
	'duration' => '10000ms',
);
is($obj->{'duration'}, 10000);
isa_ok($obj, 'Video::Pattern');

# Test.
$obj = Video::Pattern->new(
	'image_generator' => Image::Random->new(
		'type' => 'png',
	),
);
is($obj->{'image_type'}, 'png', "Image type from 'image_generator' parameter.");
