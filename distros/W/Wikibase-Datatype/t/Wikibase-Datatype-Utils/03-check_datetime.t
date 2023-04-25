use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 15;
use Test::NoWarnings;
use Wikibase::Datatype::Utils qw(check_datetime);

# Test.
my $self = {
	'key' => '+1979-10-26T15:00:00Z',
};
eval {
	check_datetime($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad date time hour value.\n",
	"Parameter 'key' has bad date time hour value (1979-10-26T15:00:00Z).");
clean();

# Test.
$self = {
	'key' => '+1979-10-26T00:20:00Z',
};
eval {
	check_datetime($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad date time minute value.\n",
	"Parameter 'key' has bad date time minute value (1979-10-26T00:20:00Z).");
clean();

# Test.
$self = {
	'key' => '+1979-10-26T00:00:30Z',
};
eval {
	check_datetime($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad date time second value.\n",
	"Parameter 'key' has bad date time second value (1979-10-26T00:00:30Z).");
clean();

# Test.
$self = {
	'key' => '+1979-02-29T00:00:00Z',
};
eval {
	check_datetime($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad date time day value.\n",
	"Parameter 'key' has bad date time day value (1979-02-29T00:00:00Z).");
clean();

# Test.
$self = {
	'key' => '+1979-00-15T00:00:00Z',
};
eval {
	check_datetime($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad date time day value.\n",
	"Parameter 'key' has bad date time day value (1979-00-15T00:00:00Z).");
clean();

# test.
$self = {
	'key' => '+1979-13-00T00:00:00Z',
};
eval {
	check_datetime($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad date time month value.\n",
	"Parameter 'key' has bad date time day value (1979-13-00T00:00:00Z).");
clean();

# Test.
$self = {
	'key' => 'bad',
};
eval {
	check_datetime($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad date time.\n",
	"Parameter 'key' has bad date time day value (bad).");
clean();

# Test.
$self = {
	'key' => '-0210-02-14T00:00:00Z',
};
my $ret = check_datetime($self, 'key');
is($ret, undef, 'Right object is present (-0210-02-14T00:00:00Z).');

# Test.
$self = {
	'key' => '+1979-10-26T00:00:00Z',
};
$ret = check_datetime($self, 'key');
is($ret, undef, 'Right object is present (+1979-10-26T00:00:00Z).');

# Test.
$self = {
	'key' => '-0210-02-00T00:00:00Z',
};
$ret = check_datetime($self, 'key');
is($ret, undef, 'Right object is present (-0210-02-00T00:00:00Z).');

# Test.
$self = {
	'key' => '+1979-10-00T00:00:00Z',
};
$ret = check_datetime($self, 'key');
is($ret, undef, 'Right object is present (+1979-10-00T00:00:00Z).');

# Test.
$self = {
	'key' => '-0210-00-00T00:00:00Z',
};
$ret = check_datetime($self, 'key');
is($ret, undef, 'Right object is present (-0210-00-00T00:00:00Z).');

# Test.
$self = {
	'key' => '+1979-00-00T00:00:00Z',
};
$ret = check_datetime($self, 'key');
is($ret, undef, 'Right object is present (+1979-00-00T00:00:00Z).');

# Test.
$self = {
	'key' => '-34000-00-00T00:00:00Z',
};
$ret = check_datetime($self, 'key');
is($ret, undef, 'Right object is present (-34000-00-00T00:00:00Z).');
