#!/usr/bin/perl

use strict;
use warnings;

use Carp ();
use Symbol::Util ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 29;

use lib 't';
use tlib;


eval q{
    package namespace::functions::Test10::Package1;
    sub a {"a"}
    sub b {"b"}
    sub c {"c"}
};
is($@, '', 'Package1 is ok');
is_deeply( list_subroutines("namespace::functions::Test10::Package1"), [qw( a b c )], 'namespace is ok' );
ok( is_code("namespace::functions::Test10::Package1::a"), 'a is sub' );
is( eval {namespace::functions::Test10::Package1->a}, "a", 'a returns a' );
ok( is_code("namespace::functions::Test10::Package1::b"), 'b is sub' );
is( eval {namespace::functions::Test10::Package1->b}, "b", 'b returns b' );
ok( is_code("namespace::functions::Test10::Package1::c"), 'c is sub' );
is( eval {namespace::functions::Test10::Package1->c}, "c", 'c returns c' );

eval q{
    package namespace::functions::Test10::Package2;
    sub a {"a"}
    sub b {"b"}
    use namespace::functions;
    sub c {"c"}
};
is($@, '', 'Package2 is ok');
is_deeply( list_subroutines("namespace::functions::Test10::Package2"), [qw( a b c )], 'namespace is ok' );
ok( is_code("namespace::functions::Test10::Package2::a"), 'a is sub' );
is( eval {namespace::functions::Test10::Package2->a}, "a", 'a returns a' );
ok( is_code("namespace::functions::Test10::Package2::b"), 'b is sub' );
is( eval {namespace::functions::Test10::Package2->b}, "b", 'b returns b' );
ok( is_code("namespace::functions::Test10::Package2::c"), 'c is sub' );
is( eval {namespace::functions::Test10::Package1->c}, "c", 'c returns c' );

eval q{
    package namespace::functions::Test10::Package3;
    sub a {"a"}
    sub b {"b"}
    use namespace::functions;
    sub c {"c"}
    no namespace::functions;
};
is($@, '', 'Package3 is ok');
is_deeply( list_subroutines("namespace::functions::Test10::Package3"), [qw( c )], 'namespace is ok' );
ok( !is_code("namespace::functions::Test10::Package3::a"), 'a is undef' );
ok( !is_code("namespace::functions::Test10::Package3::b"), 'b is undef' );
ok( is_code("namespace::functions::Test10::Package3::c"), 'c is sub' );
is( eval {namespace::functions::Test10::Package3->c}, "c", 'c returns c' );

eval q{
    package namespace::functions::Test10::Package4;
    sub a {"a"}
    sub b {"b"}
    use namespace::functions -except => ['a', 'b'];
    sub c {"c"}
    no namespace::functions -also => 'b';
};
is($@, '', 'Package4 is ok');
is_deeply( list_subroutines("namespace::functions::Test10::Package4"), [qw( a c )], 'namespace is ok' );
ok( is_code("namespace::functions::Test10::Package4::a"), 'a is code' );
is( eval {namespace::functions::Test10::Package4->a}, "a", 'a returns a' );
ok( !is_code("namespace::functions::Test10::Package4::b"), 'b is undef' );
ok( is_code("namespace::functions::Test10::Package4::c"), 'c is sub' );
is( eval {namespace::functions::Test10::Package4->c}, "c", 'c returns c' );
