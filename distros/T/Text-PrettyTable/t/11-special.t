# 11-special.t

use strict;
use warnings;

use Test::More tests => 10;
use Text::PrettyTable;

#########################

my $tpt = Text::PrettyTable->new;
ok($tpt, "new");

my $table = $tpt->tablify({ n1 => \"stringref" });
ok($table, "scalar ref");
like($table, qr/n1.*\\".*"/, "render scalarref");

$table = $tpt->tablify({ n2 => "special\x01\x07\x1f chars\x88\xdd\xff" });
ok($table, "special chars");
like($table, qr/n2(.*\\){6}/, "render special chars");

$table = $tpt->tablify({ n3 => "newline" });
ok($table, "without terminating newline");
my $table2 = $tpt->tablify({ n3 => "newline\n" });
ok($table2, "with terminating newline");
is($table, $table2, "ignore terminating newline");

$table = $tpt->tablify({ n4 => "multi\nline" });
ok($table, "newline in middle");
like($table, qr/n4.*multi.*\n.*line/, "honor multi line values");
