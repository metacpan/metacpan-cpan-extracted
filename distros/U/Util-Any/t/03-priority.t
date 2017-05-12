use Test::More qw/no_plan/;
use strict;
use lib qw(./lib t/lib);
require Util::Any;

$Util::Any::Utils->{-list} = [
                              ["List::Util", "LLLL"],
                              ["List::MoreUtils", "llll"],
                             ];

package AAA;
use Test::More;

Util::Any->import(-list => {uniq => {-as => 'luniq'}, -prefix => "ll"}, {prefix => 1, module_prefix => 1, smart_rename => 1});
ok(defined &luniq);

package BBB;
use Test::More;

Util::Any->import(-list => ['uniq', -prefix => "ll"], {prefix => 1, module_prefix => 1, smart_rename => 1});

ok(defined &lluniq);

package CCC;
use Test::More;

Util::Any->import(-list => ['uniq'], {prefix => 1, module_prefix => 1, smart_rename => 1});

ok(defined &lllluniq);

package DDD;
use Test::More;

Util::Any->import(-list => ['uniq'], {prefix => 1, smart_rename => 1});

ok(defined &list_uniq);

package EEE;
use Test::More;

Util::Any->import(-list => ['uniq'], {module_prefix => 1, smart_rename => 1});

ok(defined &lllluniq);

package FFF;
use Test::More;

Util::Any->import(-list => ['uniq'], {module_prefix => 1, prefix => 1});

ok(defined &lllluniq);

1;
