#! perl

use Text::Template::LocalVars qw[ fill_in_string ];
use Test::More;

subtest 'no package, not localized' => sub {

    package Foo1;
    use Text::Template::LocalVars qw[ fill_in_string ];
    use Test::More;

    our $a;

    fill_in_string( '', hash => { a => 2 } );

    is( $Foo1::a, 2, 'stored in package' );
};

subtest 'package, not localized' => sub {

    { package Foo2; our $a; }

    fill_in_string( '', hash => { a => 2 }, package => 'Foo2' );
    is( $Foo2::a, 2, 'stored in package' );
    is( $a, undef, 'no leaks' );
};

subtest 'no package, localized' => sub {

    package Foo3;
    use Text::Template::LocalVars qw[ fill_in_string ];
    use Test::More;

    fill_in_string( '', hash => { a => 2 }, localize => 1 );

    ok( ! exists $Foo3::{a}, 'not stored in package' );
};

subtest 'package, localized' => sub {

    fill_in_string( '', hash => { a => 2 }, package => 'Foo4', localize => 1 );
    ok( ! exists $Foo4::{a}, 'not stored in package' );
    is( $a, undef, 'no leaks' );
};


done_testing;


