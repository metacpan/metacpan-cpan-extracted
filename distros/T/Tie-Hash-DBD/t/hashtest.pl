#!/pro/bin/perl

use strict;
use warnings;

use Test::More;
use Tie::Hash::DBD;

require "./t/util.pl";

sub hashtests {
    my ($DBD, $str) = @_;

    my %hash;
    cleanup ($DBD);

    $str ||= "";
    eval { tie %hash, "Tie::Hash::DBD", dsn ($DBD), { str => $str } };

    unless (tied %hash) {
	note ("$DBD with serializer $str not functional");
	return;
	}

    ok (tied %hash,					"Hash tied with $str");

    # insert
    ok ($hash{c1} = 1,					"c1 = 1");
    ok ($hash{c2} = 1,					"c2 = 1");
    ok ($hash{c3} = 3,					"c3 = 3");

    ok ( exists $hash{c1},				"Exists c1");
    ok (!exists $hash{c4},				"Exists c4");

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
    is (scalar %hash, 2,				"Scalar");

    # Binary data
    my $anr = pack "sss", 102, 102, 025;
    ok ($hash{c4} = $anr,				"Binary value");
    ok ($hash{$anr} = 42,				"Binary key");
    ok ($hash{$anr} = $anr,				"Binary key and value");

    my %deep = deep ($DBD, $str);

    ok ($hash{deep} = { %deep },			"Deep structure");

    is_deeply ($hash{deep}, \%deep,			"Content");

    is ((tied %hash)->readonly (), 0,			"RW");
    is ((tied %hash)->readonly (1), 1,			"RO 1");
    my @w;
    eval { $SIG{__WARN__} = sub { push @w => @_; }; $hash{foo} = 42; };
    is ($hash{foo}, undef,				"FAIL");
    like ($w[0], qr{cannot store},			"Error message");
    is ((tied %hash)->readonly (2), 2,			"RO 2");
    eval { $hash{foo} = 42; };
    like ($@, qr{cannot store},				"Error message");
    is ($hash{foo}, undef,				"FAIL");
    is ((tied %hash)->readonly (0), 0,			"RW again");
    eval { $hash{foo} = 42; };
    is ($hash{foo}, 42,					"PASS");

    # clear
    %hash = ();
    $DBD eq "CSV" && $SQL::Statement::VERSION =~ m/^1.(2[0-9]|30)$/ or
	is_deeply (\%hash, {},				"Clear");

    untie %hash;
    cleanup ($DBD);
    } # hashtests

1;
