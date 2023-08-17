use strict;
use warnings;
use Test::More;

use Types::Equal qw( Eq Equ NumEq NumEqu );

{
    package StringableFoo;
    use overload '""' => sub { 'foo' };
    sub new { bless {}, shift }
}

{
    package NumberableFoo;
    use overload '0+' => sub { 123 }, fallback => 1;
    sub new { bless {}, shift }
}


subtest 'Eq' => sub {
    subtest 'display_name' => sub {
        my $type = Eq[ 'foo' ];

        is($type->display_name, "Eq['foo']", "display_name is Eq['foo']");
    };

    subtest 'check' => sub {

        subtest 'value is defined' => sub {
            my $type = Eq[ 'foo' ];

            ok( $type->check( 'foo' ), '`foo` is equal' );
            ok( !$type->check( 'bar' ), '`bar` is not equal' );
            ok( !$type->check( 'fo' ), '`fo` is not equal' );
            ok( !$type->check( 'foo ' ), '`foo ` is not equal' );
            ok( !$type->check( ' foo' ), '` foo` is not equal' );
            ok( !$type->check( undef ), 'undefined value is not equal' );
            ok( !$type->check( {} ), '{} is not equal' );
            ok( !$type->check( [] ), '[] is not equal' );
            ok( !$type->check( sub {} ), 'sub {} is not equal' );
        };

        subtest 'value is number' => sub {
            my $type = Eq[ 123 ];

            ok( $type->check( 123 ), 'number 123 is equal' );
            ok( $type->check( '123' ), "string 123 is equal" );
            ok( $type->check( 123.0 ), 'number 123.0 is equal' );
            ok( !$type->check( '123.0' ), 'string 123.0 is not equal' );
            ok( !$type->check( 'foo' ), 'foo is not equal' );
        };

        subtest 'value is strinable object' => sub {
            my $foo = StringableFoo->new;
            my $type = Eq[ $foo ];

            ok( $type->check( 'foo' ), '`foo` is equal' );
            ok( !$type->check( 'bar' ), '`bar` is not equal' );
            ok( !$type->check( 'fo' ), '`fo` is not equal' );
            ok( !$type->check( 'foo ' ), '`foo ` is not equal' );
            ok( !$type->check( ' foo' ), '` foo` is not equal' );
            ok( !$type->check( undef ), 'undefined value is not equal' );
            ok( !$type->check( {} ), '{} is not equal' );
            ok( !$type->check( [] ), '[] is not equal' );
            ok( !$type->check( sub {} ), 'sub {} is not equal' );
        };
    };

    subtest 'value' => sub {
        my $type = Eq[ 'foo' ];
        is($type->value, 'foo', 'value is foo');
    };

    subtest 'value cannot be undef' => sub {
        eval { Eq[ undef ] };
        like( $@, qr/Eq value must be defined/ );
    };

    subtest 'union' => sub {
        my $FooOrBar = Eq[ 'foo' ] | Eq[ 'bar' ];

        ok( $FooOrBar->check( 'foo' ), 'foo is valid' );
        ok( $FooOrBar->check( 'bar' ), 'bar is valid' );
        ok( !$FooOrBar->check( 'baz' ), 'baz is invalid' );
    };
};


subtest 'Equ' => sub {
    subtest 'display_name' => sub {
        is( (Equ[ 'foo' ])->display_name, "Equ['foo']", "display_name is Equ['foo']");
        is( (Equ[ undef ])->display_name, "Equ[Undef]", "display_name is Equ[Undef]");
    };

    subtest 'check' => sub {
        subtest 'value is defined' => sub {
            my $type = Equ[ 'foo' ];

            ok( $type->check( 'foo' ), '`foo` is equal' );
            ok( !$type->check( 'bar' ), '`bar` is not equal' );
            ok( !$type->check( 'fo' ), '`fo` is not equal' );
            ok( !$type->check( 'foo ' ), '`foo ` is not equal' );
            ok( !$type->check( ' foo' ), '` foo` is not equal' );
            ok( !$type->check( undef ), 'undefined value is  not equal' );
            ok( !$type->check( {} ), '{} is not equal' );
            ok( !$type->check( [] ), '[] is not equal' );
            ok( !$type->check( sub {} ), 'sub {} is not equal' );
        };

        subtest 'value is undefined' => sub {
            my $type = Equ[ undef ];

            ok( $type->check( undef ), 'undefined value is valid' );
            ok( !$type->check( '' ), 'empty string is not equal' );
            ok( !$type->check( 'foo' ), '`foo` is not equal' );
            ok( !$type->check( {} ), '{} is not equal' );
            ok( !$type->check( [] ), '[] is not equal' );
            ok( !$type->check( sub {} ), 'sub {} is not equal' );
        };

        subtest 'value is number' => sub {
            my $type = Equ[ 123 ];

            ok( $type->check( 123 ), 'number 123 is equal' );
            ok( $type->check( '123' ), "string 123 is equal" );
            ok( $type->check( 123.0 ), 'number 123.0 is equal' );
            ok( !$type->check( '123.0' ), 'string 123.0 is not equal' );
            ok( !$type->check( 'foo' ), 'foo is not equal' );
        };

        subtest 'value is strinable object' => sub {
            my $foo = StringableFoo->new;
            my $type = Equ[ $foo ];

            ok( $type->check( 'foo' ), '`foo` is equal' );
            ok( !$type->check( 'bar' ), '`bar` is not equal' );
            ok( !$type->check( 'fo' ), '`fo` is not equal' );
            ok( !$type->check( 'foo ' ), '`foo ` is not equal' );
            ok( !$type->check( ' foo' ), '` foo` is not equal' );
            ok( !$type->check( undef ), 'undefined value is not equal' );
            ok( !$type->check( {} ), '{} is not equal' );
            ok( !$type->check( [] ), '[] is not equal' );
            ok( !$type->check( sub {} ), 'sub {} is not equal' );
        };
    };

    subtest 'value' => sub {
        is( (Equ['foo'])->value, 'foo', 'value is foo' );
        is( (Equ[undef])->value, undef, 'value is undef' );
    };

    subtest 'union' => sub {
        my $FooOrBar = Equ[ 'foo' ] | Equ[ 'bar' ];

        ok( $FooOrBar->check( 'foo' ), 'foo eq foo' );
        ok( $FooOrBar->check( 'bar' ), 'bar eq bar' );
        ok( !$FooOrBar->check( 'baz' ), 'baz not eq foo or bar' );

        my $FooOrUndef = Equ[ 'foo' ] | Equ[ undef ];
        ok( $FooOrUndef->check( 'foo' ), 'foo is valid' );
        ok( $FooOrUndef->check( undef ), 'undef is valid' );
        ok( !$FooOrBar->check( 'baz' ), 'baz is invalid' );
    };
};

subtest 'NumEq' => sub {
    subtest 'display_name' => sub {
        my $type = NumEq[ 123 ];

        is($type->display_name, "NumEq[123]", "display_name is NumEq[123]");
    };

    subtest 'check' => sub {
        subtest 'value is number' => sub {
            my $type = NumEq[ 123 ];

            ok( $type->check( 123 ), 'number 123 is equal' );
            ok( $type->check( 123.0 ), 'number 123.0 is equal' );

            ok( $type->check( '123' ), "string 123 is equal" );
            ok( $type->check( '123.0' ), 'string 123.0 is equal' );

            ok( !$type->check( 124 ), 'number 124 is not equal' );
            ok( !$type->check( 'foo' ), 'foo is not equal' );
        };

        subtest 'value is numberable object' => sub {
            my $foo = NumberableFoo->new;
            my $type = NumEq[ $foo ];

            ok( $type->check( 123 ), 'number 123 is equal' );
            ok( $type->check( 123.0 ), 'number 123.0 is equal' );

            ok( $type->check( '123' ), "string 123 is equal" );
            ok( $type->check( '123.0' ), 'string 123.0 is equal' );

            ok( !$type->check( 124 ), 'number 124 is not equal' );
            ok( !$type->check( 'foo' ), 'foo is not equal' );
        };
    };

    subtest 'value' => sub {
        is( (NumEq[ 123 ])->value, 123, 'value is 123');
        is( (NumEq[ "123" ])->value, 123, 'value is 123');

        subtest 'value cannot be undef' => sub {
            eval { NumEq[ undef ] };
            like( $@, qr/Eq value must be defined/ );
        };

        subtest 'value must be number' => sub {
            eval { NumEq[ 'foo' ] };
            like( $@, qr/NumEq value must be number/ );
        };
    };
};

subtest 'NumEqu' => sub {
    subtest 'display_name' => sub {
        is( (NumEqu[123])->display_name, "NumEqu[123]", "display_name is NumEqu[123]");
        is( (NumEqu[undef])->display_name, "NumEqu[Undef]", "display_name is NumEqu[Undef]");
    };

    subtest 'check' => sub {
        subtest 'value is number' => sub {
            my $type = NumEqu[ 123 ];

            ok( $type->check( 123 ), 'number 123 is equal' );
            ok( $type->check( 123.0 ), 'number 123.0 is equal' );

            ok( $type->check( '123' ), "string 123 is equal" );
            ok( $type->check( '123.0' ), 'string 123.0 is equal' );

            ok( !$type->check( 124 ), 'number 124 is not equal' );
            ok( !$type->check( 'foo' ), 'foo is not equal' );
        };

        subtest 'value is undefined' => sub {
            my $type = NumEqu[ undef ];

            ok( $type->check( undef ), 'undefined value is valid' );
            ok( !$type->check( 123 ), 'number 123 is not equal' );
            ok( !$type->check( '' ), 'empty string is not equal' );
            ok( !$type->check( 'foo' ), '`foo` is not equal' );
            ok( !$type->check( {} ), '{} is not equal' );
            ok( !$type->check( [] ), '[] is not equal' );
            ok( !$type->check( sub {} ), 'sub {} is not equal' );
        };

        subtest 'value is numberable object' => sub {
            my $foo = NumberableFoo->new;
            my $type = NumEqu[ $foo ];

            ok( $type->check( 123 ), 'number 123 is equal' );
            ok( $type->check( 123.0 ), 'number 123.0 is equal' );

            ok( $type->check( '123' ), "string 123 is equal" );
            ok( $type->check( '123.0' ), 'string 123.0 is equal' );

            ok( !$type->check( 124 ), 'number 124 is not equal' );
            ok( !$type->check( 'foo' ), 'foo is not equal' );
        };
    };

    subtest 'value' => sub {
        is( (NumEqu[ 123 ])->value, 123, 'value is 123');
        is( (NumEqu[ "123" ])->value, 123, 'value is 123');

        subtest 'value must be number' => sub {
            eval { NumEqu[ 'foo' ] };
            like( $@, qr/NumEqu value must be number/ );
        };
    };
};

done_testing;
