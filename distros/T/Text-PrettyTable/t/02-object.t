# 02-object.t

use strict;
use warnings;

use Test::More tests => 15;
use Text::PrettyTable;

#########################

my $tpt = Text::PrettyTable->new;
ok($tpt, "new");
ok(UNIVERSAL::isa($tpt,"Text::PrettyTable"), "is object");
ok(UNIVERSAL::isa($tpt,"HASH"), "is hash");
my $table = $tpt->tablify({ key => "val" });
ok($table, "method");
like($table, qr/key.*val/s, "rendered hash");
like($table, qr/──/s, "default object with unibox");
unlike($table, qr/--/s, "default object without dashes");

$tpt = Text::PrettyTable->new({ unibox => 0 });
ok($tpt, "new with args");
$table = $tpt->tablify({ k1 => "v1" });
like($table, qr/k1.*v1/s, "new args method rendered hash");
like($table, qr/--/s, "new args method non-unibox has dashes");
unlike($table, qr/──/s, "new args method without unibox");

$table = $tpt->tablify({ k2 => "v2" }, { unibox => 1 });
ok($table, "new with args method with args");
like($table, qr/k2.*v2/s, "new args method args rendered hash");
like($table, qr/──/s, "new args method honor override args unibox");
unlike($table, qr/--/s, "new args method honor override args dashes");
