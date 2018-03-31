#!/pro/bin/perl

use strict;
use warnings;

use Test::More;
use Tie::Hash::DBD;

require "./t/util.pl";

my %hash;
my $DBD = "CSV";
cleanup ($DBD);
my $tbl = "t_tie_43_$$"."_persist";
my $dsn = dsn ($DBD);
eval { tie %hash, "Tie::Hash::DBD", $dsn, { tbl => $tbl } };

tied %hash or plan_fail ($DBD);

ok (tied %hash,				"Hash tied");

my %data = (
    UND => undef,
    IV  => 3,
    NV  => 3.14159265358979,
    PV  => "\xcf\x80",
    );
DBD::CSV->VERSION < 0.48 and delete $data{PV};
my $data = $dsn =~ m/utf8/ ? _bindata () : "123\x{ff}";

ok (%hash = %data,			"Set data");
is_deeply (\%hash, \%data,		"Get data");

ok ($hash{tux} = $data,			"Set binary from pack");
is ($hash{tux},  $data,			"Get binary from pack");

ok (untie %hash,			"Untie");
is (tied %hash, undef,			"Untied");

is_deeply (\%hash, {},			"Empty");

untie %hash;

tie %hash, "Tie::Hash::DBD", _dsn ($DBD), { tbl => $tbl };

ok (tied %hash,				"Hash re-tied");

is (delete $hash{tux}, $data,		"Get binary from pack");
is_deeply (\%hash, \%data,		"Get data again");

ok ((tied %hash)->drop,			"Make table temp");

# clear
%hash = ();
$SQL::Statement::VERSION =~ m/^1.(2[0-9]|30)$/ or
    is_deeply (\%hash, {},		"Clear");

untie %hash;
cleanup ($DBD);

done_testing;
