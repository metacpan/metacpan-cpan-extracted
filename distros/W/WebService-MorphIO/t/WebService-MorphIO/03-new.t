# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 9;
use Test::NoWarnings;
use WebService::MorphIO;

# Test.
eval {
	WebService::MorphIO->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n",
	"Unknown parameter ''.");
clean();

# Test.
eval {
	WebService::MorphIO->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");
clean();

# Test.
eval {
	WebService::MorphIO->new;
};
is($EVAL_ERROR, "Parameter 'api_key' is required.\n",
	"Parameter 'api_key' is required.");
clean();

# Test.
eval {
	WebService::MorphIO->new(
		'api_key' => 'FooBar',
	);
};
is($EVAL_ERROR, "Parameter 'project' is required.\n",
	"Parameter 'project' is required.");
clean();

# Test.
my $obj = WebService::MorphIO->new(
	'api_key' => 'FooBar',
	'project' => 'foo/bar',
);
isa_ok($obj, 'WebService::MorphIO');
is($obj->{'project'}, 'foo/bar/', "Check project name without '/'.");

# Test.
$obj = WebService::MorphIO->new(
	'api_key' => 'FooBar',
	'project' => 'foo/bar/',
);
is($obj->{'project'}, 'foo/bar/', "Check project name with '/'.");

# Test.
$obj = WebService::MorphIO->new(
	'api_key' => 'FooBar',
	'project' => 'foo/bar/',
	'web_uri' => 'http://example.com',
);
is($obj->{'web_uri'}, 'http://example.com/',
	"Check web URI name without '/'.");
