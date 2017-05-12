use Test::More tests => 1;

use qbit;

use FindBin qw($Bin);
use lib $Bin;

require_class('Class::Test');
new_ok('Class::Test');
