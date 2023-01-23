#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Text::Treesitter::Query;

# Technically we can test the query predicate functions as class methods; we
# don't currently need an instance.
my $query = "Text::Treesitter::Query";

ok(  $query->test_predicate( "eq?", "abc", "abc" ), '#eq? true' );
ok( !$query->test_predicate( "eq?", "123", "abc" ), '#eq? false' );

ok(  $query->test_predicate( "not-eq?", "123", "abc" ), '#not-eq? true' );
ok( !$query->test_predicate( "not-eq?", "abc", "abc" ), '#not-eq? false' );

ok(  $query->test_predicate( "match?", "abc", "[a-z]" ), '#match? true' );
ok( !$query->test_predicate( "match?", "123", "[a-z]" ), '#match? false' );

ok(  $query->test_predicate( "match?", "*x*", "[a-z]" ), '#match? is not anchored' );
ok( !$query->test_predicate( "match?", "*x*", '^[a-z]$' ), '#match? can be anchored' );

ok(  $query->test_predicate( "not-match?", "123", "[a-z]" ), '#not-match? true' );
ok( !$query->test_predicate( "not-match?", "abc", "[a-z]" ), '#not-match? false' );

ok(  $query->test_predicate( "contains?", "abc", "X", "b" ), '#contains? true' );
ok( !$query->test_predicate( "contains?", "123", "X", "b" ), '#contains? false' );

ok(  $query->test_predicate( "any-of?", "abc", "XYZ", "abc" ), '#any-of? true' );
ok( !$query->test_predicate( "any-of?", "123", "XYZ", "abc" ), '#any-of? false' );

done_testing;
