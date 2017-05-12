
use Validate::NPI;

use Test::Simple tests => 3;

my @msg;

ok( validate_npi('1234567893'), 'correct validation' );
ok( !validate_npi('12345',\@msg) && shift @msg eq "NPI must be exactly 10 digits long", 'fail for wrong length value' );
ok( !validate_npi('1234567891',\@msg) && shift @msg eq "NPI does not validate", 'fail for bad validation' );
