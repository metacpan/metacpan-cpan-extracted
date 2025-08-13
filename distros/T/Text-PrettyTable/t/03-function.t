# 03-function.t

use strict;
use warnings;

use Test::More tests => 9;
use Text::PrettyTable qw(pretty_table);

#########################

ok(defined &pretty_table, "imported");
my $table = pretty_table({ key => "val" });
ok($table, "function");
like($table, qr/key.*val/s, "rendered hash");
like($table, qr/──/s, "default unibox");
unlike($table, qr/--/s, "not dashes");
$table = pretty_table({ k1 => "v1" }, { unibox => 0 });
ok($table, "function with args");
like($table, qr/k1.*v1/s, "function args rendered hash");
like($table, qr/--/s, "function args non-unibox has dashes");
unlike($table, qr/──/s, "function args without unibox");
