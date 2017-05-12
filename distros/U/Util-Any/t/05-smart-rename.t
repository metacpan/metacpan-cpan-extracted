use Test::More 'no_plan';
use lib qw(./lib t/lib);

package AA;
use Test::More;

use SmartRename -utf8, {smart_rename => 1};

ok(!defined(&utf8_is_utf8));
ok(!defined(&utf8_utf8_upgrade));
ok(defined(&is_utf8));
ok(defined(&utf8_upgrade));
ok(defined(&utf8_downgrade));

package BB;
use Test::More;

use SmartRename -utf8 => {is_utf8 => {-as => 'utf_flagged'}, -prefix => 'xx_', smart_rename => 1};

ok(!defined(&xx_is_utf8));
ok(defined(&utf_flagged));
ok(defined(&xx_utf8_upgrade));
ok(defined(&xx_downgrade));

