# 10-render.t

use strict;
use warnings;

use Test::More tests => 23;
use Text::PrettyTable;

#########################

my $tpt = Text::PrettyTable->new;
ok($tpt, "new");

# default
my $table = $tpt->tablify({ k1 => "v2" });
ok($table, "default hash");
like($table, qr/k1.*v2/, "rendered hash");
like($table, qr/──/s, "default with unibox");
unlike($table, qr/--/s, "default without dashes");

# simple hash
$table = $tpt->tablify({ k2 => "v2" }, { unibox => 0 });
ok($table, "hash without unibox");
like($table, qr/k2.*v2/, "still rendered hash");
like($table, qr/--/s, "hash args with dashes");
unlike($table, qr/──/s, "hash args without unibox");

# simple array
$table = $tpt->tablify([qw(v3 v4)], { unibox => 0 });
ok($table, "array without unibox");
like($table, qr/v3.*\n.*v4/, "rendered array");
unlike($table, qr/v3.*v4/, "not rendered hash");
like($table, qr/--/s, "array args with dashes");
unlike($table, qr/──/s, "array args without unibox");

# array of hashes
my $data = [
  { id => "22",  name => "alice",  age => 11 },
  { id => "33",  name => "bobby",  age => 13 },
  { id => "55",  name => "chuck",  age => 18 },
];

# with sort 1
$table = $tpt->tablify($data, { sort => [qw[id name age]] });
#warn "sort 1:\n$table\n";
ok($table, "array of hashes sort 1");
like($table, qr/22.*ali.*11.*\n.*33.*bob.*13.*\n.*55.*chu.*18/, "render sort 1");

# with sort 2
$table = $tpt->tablify($data, { sort => [qw[id age name]] });
#warn "sort 2:\n$table\n";
ok($table, "array of hashes sort 2");
like($table, qr/22.*11.*ali.*\n.*33.*13.*bob.*\n.*55.*18.*chu/, "render sort 2");

# with sort 3 dup fields
$table = $tpt->tablify($data, { sort => [qw[id age name age]] });
#warn "sort 3:\n$table\n";
ok($table, "array of hashes sort 3 dups");
like($table, qr/22.*11.*ali.*11.*\n.*33.*13.*bob.*13.*\n.*55.*18.*chu.*18/, "render sort 3 dups");

# with sort 4 missing fields
$table = $tpt->tablify($data, { sort => [qw[id name]] });
#warn "sort 4:\n$table\n";
ok($table, "array of hashes sort 4 missing");
like($table, qr/22.*ali.*\n.*33.*bob.*\n.*55.*chu/, "render sort 4");
unlike($table, qr/11|13|18/, "render sort missing fields");
