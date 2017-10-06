#! perl

use Test2::V0;

use Types::PDL -types, -coercions;

use PDL::Lite;


#<<< notidy

subtest 'PiddleFromAny' => sub {

    my $t = Piddle->plus_coercions( PiddleFromAny );

    for my $test (
                  [ '4           ',            4, 1 ],
                  [ '[2]         ',          [2], 1 ],
                  [ '[ [2], [2] ]', [ [2], [2] ], 1 ],
                  [ '"foo"'       ,        'foo', 0 ],
                  ) {

        my ( $label, $value, $pass ) = @$test;

        subtest qq[value => $label] => sub {

            ok( !$t->check( $value ), 'value before coercion is not a piddle' );

            my $pdl;
            ok(
                lives { $pdl = $t->coerce( $value ) },
                "coercion didn't throw",
            );

            ok( !$pass ^ $t->check( $pdl ),
                ("value could not be coerced",
                 "value could be coerced"
                )[$pass]
              );
       };

    }

};


#>>> tidy once more
done_testing;
