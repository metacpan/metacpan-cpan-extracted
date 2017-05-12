use Test::More;
use strict;

BEGIN {
    eval("use Class::Struct");
    plan skip_all => "Class::Struct not installed" if $@;
}

package ClassStructTest;

use Class::Struct;

# declare the struct
struct( 'ClassStructTest', { count => '$', stuff => '%' } );

package TestCases;

use Test::Pockito;

use Test::Simple tests => 2;
{

    my $pocket = Test::Pockito->new("Foo");
    my $mock   = $pocket->mock("ClassStructTest");

    $pocket->when( $mock->count )->then(0);
    $pocket->when( $mock->count(1) )->then(1);

    ok( $mock->count == 0,    "Getter worked" );
    ok( $mock->count(1) == 1, "Setter worked" );
}
