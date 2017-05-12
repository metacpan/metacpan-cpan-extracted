#!/usr/bin/perl

use warnings;
use strict;

use Test::Tester;
use Test::More;
use Test::Exports;

my $pkg = new_import_pkg;

{
    package t::Export;

    sub foo { 1 }
    sub bar { 1 }

    no strict "refs";
    *{"$pkg\::foo"} = \&foo;
    *{"$pkg\::bar"} = \&bar;
}

check_test
    sub { is_import "foo", "t::Export", "foo imported" },
    { ok => 1, name => "foo imported" },
    "is_import with one OK import";

check_test
    sub { is_import "foo", "bar", "t::Export", "foo+bar imported" },
    { ok => 1, name => "foo+bar imported" },
    "is_import with two OK imports";

check_test
    sub { is_import "baz", "t::Export", "baz imported" },
    { ok => 0, name => "baz imported", diag => <<DIAG },
Expected subs to be imported from t::Export:
  &$pkg\::baz is not defined
DIAG
    "is_import with nonexistent import";

check_test
    sub { is_import "foo", "t::NotThere", "foo not there" },
    { ok => 0, name => "foo not there", diag => <<DIAG },
Expected subs to be imported from t::NotThere:
  &$pkg\::foo is not imported correctly
DIAG
    "is_import with incorrect import";

{
    package t::Quux;
    no strict "refs";
    sub quux { 1 }
    *{"$pkg\::quux"} = \&quux;
}

check_test
    sub { is_import qw/foo baz quux/, "t::Export", "multi" },
    { ok => 0, name => "multi", diag => <<DIAG },
Expected subs to be imported from t::Export:
  &$pkg\::baz is not defined
  &$pkg\::quux is not imported correctly
DIAG
    "is_import with mixed imports";

$pkg = new_import_pkg;

check_test
    sub { is_import "foo", "t::Export", "new pkg" },
    { ok => 0, name => "new pkg", diag => <<DIAG },
Expected subs to be imported from t::Export:
  &$pkg\::foo is not defined
DIAG
    "is_import keeps up with new_import_pkg";

check_test
    sub { is_import "t::NotThere", "no subs" },
    { ok => 1, name => "no subs" },
    "is_import with no subs";

$pkg = new_import_pkg;

{
    package t::Export;
    no strict "refs";
    *{"$pkg\::foo"} = \&foo;
}

check_test
    sub { cant_ok "bar", "!bar" },
    { ok => 1, name => "!bar" },
    "cant_ok with nonexistent sub";

check_test
    sub { cant_ok "foo", "!foo" },
    { ok => 0, name => "!foo", diag => <<DIAG },
    &$pkg\::foo is imported from t::Export
DIAG
    "cant_ok with imported sub";

eval "package $pkg; sub baz { 1 }";

check_test
    sub { cant_ok "baz", "!baz" },
    { ok => 0, name => "!baz", diag => <<DIAG },
    &$pkg\::baz is imported from $pkg
DIAG
    "cant_ok with non-imported sub";

check_test
    sub { cant_ok qw/foo bar baz/, "multi" },
    { ok => 0, name => "multi", diag => <<DIAG },
    &$pkg\::foo is imported from t::Export
    &$pkg\::baz is imported from $pkg
DIAG
    "cant_ok with multiple subs";

done_testing;
