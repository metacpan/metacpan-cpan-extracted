use strict;
use warnings;

use Validate::Simple;

use Test::More;

my @tests = (
    {
        name => 'Not a hashref',
        specs => [
            [ [ var => { type => 'number' } ], 0 ],
            [ [ { var=> { type => 'any' } } ], 0 ],
            [ { var => [ type => 'any' ] },    0 ],
            [ { var => 'any' },                0 ],
            [ { var => { type => 'any' } },    1 ],
            [ { var => { } },                  1 ],
        ],
    },
    {
        name => 'Bad specs',
        specs => [
            [ { var => { type => 'something' } }, 0 ],
            [ { var => { type => 'array' } },     0 ],
            [ { var => { undefined => 1 } },      0 ],
            [
                {
                    var => {
                        type => 'hash',
                        of => 'string',
                    },
                },
                0
            ],
        ],
    },
);

my $test_count = 0;
for my $test ( @tests ) {
    $test_count += scalar @{ $test->{specs} };
}

plan tests =>
    1
    + $test_count;

my $validate = new_ok( 'Validate::Simple' );

for my $test ( @tests ) {
    my $name = $test->{name};
    for my $t ( @{ $test->{specs} } ) {
        my ( $spec, $expected_true ) = @$t;
        $expected_true
            ? ok( $validate->validate_specs( $spec ),
                  "Validation $name: Passed as expected"
                      . " - "
                      . join(';', $validate->delete_errors())
                  )
            : ok( !$validate->validate_specs( $spec ),
                  "Validation $name: Did not passed as expected"
                      . " - "
                      . join(';', $validate->delete_errors())
                  );
    }
}

1;
