#!/pro/bin/perl

use strict;
use warnings;

use Test::More;
use Tie::Hash::DBD;

require "./t/util.pl";

my %hash;
my $DBD = "Oracle";
cleanup ($DBD);
eval { tie %hash, "Tie::Hash::DBD", dsn ($DBD) };

tied %hash or plan_fail ($DBD);

diag "Using DBD::$DBD-", "DBD::$DBD"->VERSION, "\n";

ok (tied %hash,						"Hash tied");

# insert
ok ($hash{c1} = 1,					"c1 =  1");
is ($hash{c1},  1,					"c1 == 1");
ok ($hash{c2} = 1,					"c2 =  1");
is ($hash{c2},  1,					"c2 == 1");
ok ($hash{c3} = 3,					"c3 =  3");
is ($hash{c3},  3,					"c3 == 3");

ok ( exists $hash{c1},					"Exists c1");
ok (!exists $hash{c4},					"Exists c4");

# update
ok ($hash{c2} = 2,					"c2 =  2");
is ($hash{c2},  2,					"c2 == 2");

# delete
is (delete ($hash{c3}), 3,				"Delete c3");

# select
is ($hash{c1}, 1,					"Value of c1");

# keys, values
is_deeply ([ sort keys   %hash ], [ "c1", "c2" ],	"Keys");
is_deeply ([ sort values %hash ], [ 1, 2 ],		"Values");

is_deeply (\%hash, { c1 => 1, c2 => 2 },		"Hash");

# Scalar/count
is (scalar %hash, 2,					"Scalar");

# Binary data
my $anr = pack "sss", 102, 102, 025;
ok ($hash{c4} = $anr,					"Binary value");
is ($hash{c4},  $anr,					"Binary value");
ok ($hash{$anr} = 42,					"Binary key");
is ($hash{$anr},  42,					"Binary key");
ok ($hash{$anr} = $anr,					"Binary key and value");
is ($hash{$anr},  $anr,					"Binary key and value");

my $data = _bindata ();
ok ($hash{tux} = $data,					"Binary from pack");
is ($hash{tux},  $data,					"Binary from pack");

# clear
%hash = ();
is_deeply (\%hash, {},					"Clear");

untie %hash;
cleanup ($DBD);

done_testing;
