use Test::More tests => 2;

use qbit;

use FindBin qw($Bin);
use lib $Bin;

require_class('Class::Test');
new_ok('Class::Test');

dynamic_loading('Class::Test::');
new_ok('Class::Test::Dynamic');
