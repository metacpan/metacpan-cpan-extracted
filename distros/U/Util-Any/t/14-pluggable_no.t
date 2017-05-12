use Test::More qw/no_plan/;

use lib qw(./lib t/lib);

require UtilPluggable;

package BBB;

UtilPluggable->import(-pluggable2, {plugin => '0'});
use Test::More;
ok(!defined &UtilPluggable::Plugin::Pluggable2::utils);
ok(!defined &UtilPluggable::Plugin::Pluggable::utils);
ok(!defined &test);
ok(!defined &test2);
ok(!defined &camelize);
ok(!defined &test3);
delete @INC{qw{UtilPluggable/Plugin/Pluggable.pm UtilPluggable/Plugin/Pluggable2.pm}};
undef &UtilPluggable::Plugin::Pluggable::utils;
undef &UtilPluggable::Plugin::Pluggable2::utils;

package AAA;

UtilPluggable->import(-pluggable, {plugin => '0'});
use Test::More;

ok(!defined &UtilPluggable::Plugin::Pluggable2::utils);
ok(!defined &UtilPluggable::Plugin::Pluggable::utils);
ok(!defined &test);
ok(!defined &test2);
ok(defined &camelize);
ok(!defined &test3);

package CCC;

use Test::More;
UtilPluggable->import(-pluggable, -pluggable2, {plugin => '0'});

ok(!defined &test);
ok(!defined &test2);
ok(defined &camelize);
ok(!defined &test3);

package DDD;

use Test::More;
UtilPluggable->import(-all, {plugin => '0'});

ok(!defined &test);
ok(!defined &test2);
ok(defined &camelize);
ok(!defined &test3);
