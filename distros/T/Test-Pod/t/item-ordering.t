#!perl -T

use strict;

use Test::Builder::Tester tests => 2;
use Test::More;

BEGIN {
    use_ok( 'Test::Pod' );
}

my $file = 't/item-ordering.pod';
test_out( "not ok 1 - POD test for $file" );
pod_file_ok( $file );
test_fail(-1);
test_diag(
    ( Pod::Simple->VERSION == 3.24 ? (
        "$file (17): Expected text matching /\\s+[^\\*\\d]/ after '=item'",
        "$file (21): Expected text matching /\\s+[^\\*\\d]/ after '=item'",
        "$file (32): You can't have =items (as at line 36) unless the first thing after the =over is an =item",
    ) : Pod::Simple->VERSION >= 3.27 ? (
        "$file (17): Expected text after =item, not a number",
        "$file (21): Expected text after =item, not a number",
        "$file (32): You can't have =items (as at line 36) unless the first thing after the =over is an =item",
        "$file (32): =over without closing =back",
    ) : Pod::Simple->VERSION >= 3.25 ? (
        "$file (17): Expected text after =item, not a number",
        "$file (21): Expected text after =item, not a number",
        "$file (32): You can't have =items (as at line 36) unless the first thing after the =over is an =item",
    ) : (
        "$file (32): You can't have =items (as at line 36) unless the first thing after the =over is an =item",
    ))
);
test_test( "$file is bad" );
