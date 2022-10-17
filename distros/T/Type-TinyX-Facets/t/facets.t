#!perl

use Test2::V0;
use Test::Lib;

no warnings 'deprecated';

use My::Types;
use My::DeprecatedTypes;

for my $class ( 'My::Types', 'My::DeprecatedTypes' ) {

    subtest $class => sub {

        my $TYPE;

        $TYPE = 'MinMax';
        subtest $TYPE => sub {

            my $gen = \&{"$class\::$TYPE"};

            my $type;
            ok(
                lives {
                    $type = &$gen( [ min => -3, max => 5 ] );
                },
                "construct $TYPE type with valid parameters"
            );

            ok( !$type->check( -3.1 ), 'too small' );
            ok( !$type->check( 5.1 ),  'too big' );
            ok( $type->check( 0 ),     'just right' );

            ok(
                lives {
                    $type = &$gen( [ min => -3 ] );
                },
                "construct $TYPE type with single facet out of several"
            );

            like(
                dies {
                    $type = &$gen( [ positive => 1 ] );
                },
                qr/unrecogni[sz]ed parameter.*positive.*/,
                "construct $TYPE type with unknown parameter"
            );

            like(
                dies {
                    $type = &$gen( [ min => 'huh?' ] );
                },
                qr/must be a number/,
                "construct $TYPE type with illegal parameter value"
            );

        };

        $TYPE = 'Bounds';
        subtest $TYPE => sub {

            my $gen = \&{"$class\::$TYPE"};

            my $type;
            ok(
                lives {
                    $type = &$gen( [ min => -3, max => 5 ] );
                },
                "construct $TYPE type with valid parameters"
            ) or diag $@;

            ok( !$type->check( -3.1 ), 'too small' );
            ok( !$type->check( 5.1 ),  'too big' );
            ok( $type->check( 0 ),     'just right' );

            ok(
                lives {
                    $type = &$gen( [ min => -3 ] );
                },
                "construct $TYPE type with single facet out of several"
            );

            like(
                dies {
                    $type = &$gen( [ positive => 1 ] );
                },
                qr/unrecogni[sz]ed parameter.*positive.*/,
                "construct $TYPE type with unknown parameter"
            );

            like(
                dies {
                    $type = &$gen( [ min => 5, max => 3 ] );
                },
                qr/constraint fails condition/,
                "construct $TYPE type with illegal conditions"
            );

            like(
                dies {
                    $type = &$gen( [ min => 'huh?' ] );
                },
                qr/must be a number/,
                "construct $TYPE type with illegal parameter value"
            );

        };

        $TYPE = 'Positive';
        subtest $TYPE => sub {
            my $gen = \&{"$class\::$TYPE"};

            my $type;
            ok(
                lives {
                    $type = &$gen( [ min => -3, max => 5, positive => 1 ] );
                },
                "construct $TYPE type with valid parameters"
            );

            ok( !$type->check( -1 ),  'negative' );
            ok( !$type->check( 0 ),   'zero' );
            ok( !$type->check( 5.1 ), 'too big' );
            ok( $type->check( 0.1 ),  'just right' );

        };

    };

}
done_testing;
