use strict;
use warnings;

use Cpanel::JSON::XS::Type;
use English;
use Error::Pure::Utils qw(clean);
use Test::JSON::Type;
use Test::More 'tests' => 14;
use Test::NoWarnings;

# Test.
my $input_json = '{}';
my $expected_type_hr = {};
is_json_type($input_json, $expected_type_hr,
	'Blank JSON structure and expected blank type.');

# Test.
$input_json = <<'END';
{
	"int": 1
}
END
$expected_type_hr = {
	'int' => JSON_TYPE_INT,
};
is_json_type($input_json, $expected_type_hr,
	'JSON structure with integer and expected type.');

# Test.
$input_json = <<'END';
{
	"string": "foo"
}
END
$expected_type_hr = {
	'string' => JSON_TYPE_STRING,
};
is_json_type($input_json, $expected_type_hr,
	'JSON structure with string and expected type.');

# Test.
$input_json = <<'END';
{
	"bool": true
}
END
$expected_type_hr = {
	'bool' => JSON_TYPE_BOOL,
};
is_json_type($input_json, $expected_type_hr,
	'JSON structure with bool and expected type.');

# Test.
$input_json = <<'END';
{
	"float": 1.2345
}
END
$expected_type_hr = {
	'float' => JSON_TYPE_FLOAT,
};
is_json_type($input_json, $expected_type_hr,
	'JSON structure with float and expected type.');

# Test.
$input_json = <<'END';
{
	"null": null
}
END
$expected_type_hr = {
	'null' => JSON_TYPE_NULL,
};
is_json_type($input_json, $expected_type_hr,
	'JSON structure with null and expected type.');

# Test.
$input_json = <<'END';
{
	"array": []
}
END
$expected_type_hr = {
	'array' => [],
};
is_json_type($input_json, $expected_type_hr,
	'JSON structure with blank array and expected type.');

# Test.
$input_json = <<'END';
{
	"array": [1,2,3]
}
END
$expected_type_hr = {
	'array' => json_type_arrayof(JSON_TYPE_INT),
};
is_json_type($input_json, $expected_type_hr,
	'JSON structure with integer array and expected variable integer array type.');

# Test.
$input_json = <<'END';
{
	"array": [1,2,3]
}
END
$expected_type_hr = {
	'array' => json_type_arrayof(JSON_TYPE_INT),
};
is_json_type($input_json, $expected_type_hr,
	'JSON structure with integer array and expected variable integer array type.');

# Test.
$input_json = <<'END';
{
	"array": [1,2,3]
}
END
$expected_type_hr = {
	'array' => [
		JSON_TYPE_INT,
		JSON_TYPE_INT,
		JSON_TYPE_INT,
	],
};
is_json_type($input_json, $expected_type_hr,
	'Blank JSON structure with 3 integer array and expected strict type.');

# Test.
$input_json = <<'END';
{
	"array": ["foo", 1, true, null, 1.2345, {"key": "value"}]
}
END
$expected_type_hr = {
	'array' => [
		JSON_TYPE_STRING,
		JSON_TYPE_INT,
		JSON_TYPE_BOOL,
		JSON_TYPE_NULL,
		JSON_TYPE_FLOAT,
		json_type_hashof(JSON_TYPE_STRING),
	],
};
is_json_type($input_json, $expected_type_hr,
	'JSON structure with complex array and expected type.');

# Test.
$input_json = undef;
$expected_type_hr = {};
eval {
	is_json_type($input_json, $expected_type_hr);
};
is($EVAL_ERROR, "JSON string to compare is required.\n",
	"JSON string to compare is required.");
clean();

# Test.
$input_json = '';
$expected_type_hr = {};
eval {
	is_json_type($input_json, $expected_type_hr);
};
is($EVAL_ERROR, "JSON string isn't valid.\n",
	"JSON string isn't valid.");
clean();
