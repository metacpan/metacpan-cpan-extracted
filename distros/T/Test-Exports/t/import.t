#!/usr/bin/perl

use strict;
use warnings;

use Test::Tester;
use Test::More;

use Test::Exports;

{
    package t::Import::OK;
    sub import { 1 }
}
{
    package t::Import::False;
    sub import { return }
}
{
    package t::Import::Die;
    # include \n to avoid matching 'at...line...'
    sub import { die "Bad import\n" }
}

check_test
    sub { import_ok "t::Import::OK", [], "import OK" },
    { ok => 1, name => "import OK" },
    "import_ok successful import";

check_test
    sub { import_ok "t::Import::False", [], "import false" },
    { ok => 1, name => "import false" },
    "import_ok false import";

my $finished_eval;
check_test
    sub {
        eval {
            import_ok "t::Import::Die", [], "import die";
            $finished_eval = 1;
        };
    },
    # extra depth for the eval{}
    { ok => 0, name => "import die", depth => 2, diag => <<DIAG },
t::Import::Die->import() failed:
Bad import

DIAG
    "import_ok dying import";

ok $finished_eval, "import_ok caught exception";

check_test
    sub { import_nok "t::Import::OK", [], "import OK" },
    { ok => 0, name => "import OK", diag => <<DIAG },
t::Import::OK->import() succeeded where it should have failed.
DIAG
    "import_nok successful import";

check_test
    sub { import_nok "t::Import::False", [], "import false" },
    { ok => 0, name => "import false", diag => <<DIAG },
t::Import::False->import() succeeded where it should have failed.
DIAG
    "import_nok false import";

$finished_eval = 0;
check_test
    sub { 
        eval {
            import_nok "t::Import::Die", [], "import die";
            $finished_eval = 1;
        };
    },
    { ok => 1, name => "import die", depth => 2 },
    "import_nok dying import";

ok $finished_eval, "import_nok caught exception";

my @import;
{
    package t::Import::Args;
    sub import { @import = @_ }
}
{
    package t::Import::ArgsFail;
    sub import { @import = @_; die "argsfail\n" }
}

@import = ();
check_test
    sub { import_ok "t::Import::Args", [1, 2, 3], "import args" },
    { ok => 1, name => "import args" },
    "import_ok with args";
is_deeply \@import, ["t::Import::Args", 1, 2, 3], 
    "with correct args";

@import = ();
check_test
    sub { import_ok "t::Import::ArgsFail", [1, 2, 3], "import args" },
    { ok => 0, name => "import args", diag => <<DIAG },
t::Import::ArgsFail->import(1, 2, 3) failed:
argsfail

DIAG
    "bad import_ok with args";
is_deeply \@import, ["t::Import::ArgsFail", 1, 2, 3], 
    "correct args anyway";

@import = ();
check_test
    sub { import_nok "t::Import::Args", [1, 2, 3], "import args" },
    { ok => 0, name => "import args", diag => <<DIAG },
t::Import::Args->import(1, 2, 3) succeeded where it should have failed.
DIAG
    "import_nok with args";
is_deeply \@import, ["t::Import::Args", 1, 2, 3], 
    "correct args";

@import = ();
check_test
    sub { import_nok "t::Import::ArgsFail", [1, 2, 3], "import args" },
    { ok => 1, name => "import args" },
    "bad import_nok with args";
is_deeply \@import, ["t::Import::ArgsFail", 1, 2, 3], 
    "correct args";

@import = ();
check_test
    sub { import_ok "t::Import::Args", [4, 5] },
    { ok => 1, name => "t::Import::Args->import(4, 5) succeeds" },
    "import_ok with default name";
is_deeply \@import, ["t::Import::Args", 4, 5],
    "correct args";

@import = ();
check_test
    sub { import_ok "t::Import::Args" },
    { ok => 1, name => "t::Import::Args->import() succeeds" },
    "import_ok with default args";
is_deeply \@import, ["t::Import::Args"],
    "correct args";

@import = ();
check_test
    sub { import_nok "t::Import::ArgsFail", [5, 6] },
    { ok => 1, name => "t::Import::ArgsFail->import(5, 6) fails" },
    "import_nok with default name";
is_deeply \@import, ["t::Import::ArgsFail", 5, 6],
    "correct args";

@import = ();
check_test
    sub { import_nok "t::Import::ArgsFail" },
    { ok => 1, name => "t::Import::ArgsFail->import() fails" },
    "import_nok with default args";
is_deeply \@import, ["t::Import::ArgsFail"],
    "correct args";

my $caller;
{
    package t::Import::Pkg;
    sub import { $caller = caller }
}

$caller = "???";
my $pkg = new_import_pkg;
check_test
    sub { import_ok "t::Import::Pkg", [], "pkg" },
    { ok => 1, name => "pkg" },
    "import_ok with package";
is $caller, $pkg, "import_ok uses correct package";

$caller = "???";
$pkg = new_import_pkg;
check_test
    sub { import_nok "t::Import::Pkg", [], "pkg" },
    { ok => 0, name => "pkg", diag => <<DIAG },
t::Import::Pkg->import() succeeded where it should have failed.
DIAG
    "import_nok with package";
is $caller, $pkg, "import_nok uses correct package";

done_testing;
