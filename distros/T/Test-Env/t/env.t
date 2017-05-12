use Test::Builder::Tester tests => 3;
use Test::Env;

my $key   = "TEST_ENV_FOO";
my $value = "BAR";
my $oops  = "BAZ";

{
local $ENV{$key} = $value;
test_out( 'ok 1' );
env_ok( $key, $value );
test_test( 'env_ok' );

$ENV{FOO} = $oops;
test_out( 'not ok 1' );
env_ok( $key, $oops );
test_diag( "    Failed test ($0 at line " . line_num(-1) . ")",
	"Environment variable [$key] has wrong value!",
	"\tExpected [$oops]",
	"\tGot [$value]");
test_test( 'env_ok catches bad value' );
}

$ENV{$key} = $value;

{
local %ENV = ();

test_out( 'not ok 1' );
env_ok( $key, $value );
test_diag( "    Failed test ($0 at line " . line_num(-1) . ")",
	"Environment variable [$key] missing!",
	"\tExpected [$value]",
	);
test_test( 'env_ok catches missing value' );
}
