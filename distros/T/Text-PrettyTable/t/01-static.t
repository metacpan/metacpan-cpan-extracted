# 01-static.t

use strict;
use warnings;

use Test::More tests => 4;
use Text::PrettyTable;

#########################

my $table = Text::PrettyTable->tablify({ key => "val" });
ok($table, "static method");
like($table, qr/key.*val/, "rendered hash");
$table = Text::PrettyTable->plain_text({ key => "val" });
ok($table, "alias method");
like($table, qr/key.*val/, "alias rendered");
