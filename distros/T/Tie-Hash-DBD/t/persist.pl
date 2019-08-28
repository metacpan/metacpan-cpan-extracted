#!/pro/bin/perl

use strict;
use warnings;

use Test::More;
use Tie::Hash::DBD;

require "./t/util.pl";

sub persisttests {
    my ($DBD, $t) = @_;

    my %hash;
    my $tbl = "t_tie_${t}_$$"."_persist";
    my $dsn = dsn ($DBD);
    eval { tie %hash, "Tie::Hash::DBD", $dsn, { tbl => $tbl } };

    tied %hash or plan_fail ($DBD);

    ok (tied %hash,			"Hash tied");

    my %data = (
	UND => undef,
	IV  => 3,
	NV  => 3.14159265358979001,
	PV  => "pi", # "\xcf\x80" binary is tested elsewhere
	);
    my $data = _bindata ();

    ok (%hash = %data,			"Set data");
    is_deeply (\%hash, \%data,		"Get data");

    ok ($hash{tux} = $data,		"Set binary from pack");
    is ($hash{tux},  $data,		"Get binary from pack");

    ok (untie %hash,			"Untie");
    is (tied %hash, undef,		"Untied");

    is_deeply (\%hash, {},		"Empty");

    untie %hash;

    tie %hash, "Tie::Hash::DBD", $dsn, { tbl => $tbl };

    ok (tied %hash,			"Hash re-tied");

    is (delete $hash{tux}, $data,	"Get binary from pack");
    is_deeply (\%hash, \%data,		"Get data again");

    ok ((tied %hash)->drop,		"Make table temp");

    # clear
    %hash = ();
    $DBD eq "CSV" && $SQL::Statement::VERSION =~ m/^1.(2[0-9]|30)$/ or
	is_deeply (\%hash, {},		"Clear");

    untie %hash;
    cleanup ($DBD);
    } # persisttests

1;
