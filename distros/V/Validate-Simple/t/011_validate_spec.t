use strict;
use warnings;

use Test::More;

my @tests = (
    {
        name => 'Not a hashref',
        specs => [
            [ [ var => { type => 'number' } ], 0, 0 ],
            [ [ { var=> { type => 'any' } } ], 0, 0 ],
            [ { var => [ type => 'any' ] },    0, 0 ],
            [ { var => 'any' },                0, 0 ],
            [ { var => { type => 'any' } },    1, 0 ],
            [ { var => { required => 1 } },    1, 1 ],
            [
                {
                    var => {
                        required => 1
                    },
                    foo => {
                        type     => 'any',
                        required => 0,
                    },
                    bar => {
                        type     => 'number',
                        required => 1,
                    },
                },
                1, 2
            ],
        ],
    },
    {
        name => 'Bad specs',
        specs => [
            [ { var => { type => 'something' } }, 0, 0 ],
            [ { var => { type => 'array' } },     0, 0 ],
            [ { var => { undefined => 1 } },      0, 0 ],
            [
                {
                    var => {
                        type => 'hash',
                        of => 'string',
                    },
                },
                0, 0
            ],
        ],
    },
);

my $test_count = 0;
for my $test ( @tests ) {
    $test_count += scalar @{ $test->{specs} };
}

plan tests =>
    1              # Use the class
    + 1            # Create an object
    + 2 * $test_count; # Tests

use_ok( 'Validate::Simple' );
my $validate = new_ok( 'Validate::Simple' );

for my $test ( @tests ) {
    my $name = $test->{name};
    for my $t ( @{ $test->{specs} } ) {
        my ( $spec, $expected_true, $required ) = @$t;
        my $req = 0;
        my $result = $validate->validate_specs( $spec, \$req );
        if ( $expected_true ) {
            ok( $result,
                "Validation $name: Passed as expected"
                    . " - "
                    . join(';', $validate->delete_errors())
                );
        }
        else {
            ok( !$result,
                "Validation $name: Did not passed as expected"
                    . " - "
                    . join(';', $validate->delete_errors())
                );
        }
        ok( $required == $req, "Validation $name: amount of required params" );
    }
}

1;
