#!/pro/bin/perl

use strict;
use warnings;

use Test::More;
use Tie::Hash::DBD;

require "./t/util.pl";

my %hash;
my $DBD = "SQLite";
cleanup ($DBD);
eval { tie %hash, "Tie::Hash::DBD", dsn ($DBD), { str => "Storable" } };

tied %hash or plan_fail ($DBD);

ok (tied %hash,						"Hash tied");

# insert
ok ($hash{c1} = 1,					"c1 = 1");
ok ($hash{c2} = 1,					"c2 = 1");
ok ($hash{c3} = 3,					"c3 = 3");

ok ( exists $hash{c1},					"Exists c1");
ok (!exists $hash{c4},					"Exists c4");

# update
ok ($hash{c2} = 2,					"c2 = 2");

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
ok ($hash{$anr} = 42,					"Binary key");
ok ($hash{$anr} = $anr,					"Binary key and value");

my %deep = (
    UND => undef,
    IV  => 1,
    NV  => 3.14159265358979,
    PV  => "string",
    PV8 => "ab\ncd\x{20ac}\t",
    PVM => $!,
    RV  => \$DBD,
    AR  => [ 1..2 ],
    HR  => { key => "value" },
    OBJ => ( bless { auto_diag => 1 }, "Text::CSV_XS" ),
    # These are not handled by Storable:
#   CR  => sub { "code"; },
#   GLB => *STDERR,
#   IO  => *{$::{STDERR}}{IO},
#   RX  => qr{^re[gG]e?x},
#   FMT => *{$::{STDOUT}}{FORMAT},
    );

ok ($hash{deep} = { %deep },				"Deep structure");

my %got = %{$hash{deep}};

if ($^O eq "MSWin32" && $deep{RV} != $got{RV}) {
    delete $deep{RV};
    delete $got{RV};
    }
is_deeply (\%got, \%deep,				"Content");

# clear
%hash = ();
is_deeply (\%hash, {},					"Clear");

untie %hash;
cleanup ($DBD);

done_testing;
