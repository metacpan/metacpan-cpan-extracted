#!/pro/bin/perl

use strict;
use warnings;

use Test::More;
use Tie::Hash::DBD;

require "./t/util.pl";

my %hash;
my $DBD = "Oracle";
cleanup ($DBD);
my $tbl = "t_tie_63_$$"."_persist";
eval { tie %hash, "Tie::Hash::DBD", dsn ($DBD), { tbl => $tbl } };

tied %hash or plan_fail ($DBD);

ok (tied %hash,				"Hash tied");

my %data = (
    UND => undef,
    IV  => 1,
    NV  => 3.14159265358979,
    PV  => "string",
    );
my $data = _bindata ();

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
is_deeply (\%hash, {},			"Clear");

untie %hash;
cleanup ($DBD);

done_testing;
