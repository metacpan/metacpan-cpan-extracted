use strict;
use warnings;

use Test::More;
use Test::Exception;

use Text::Difference;

my $diff = undef;

lives_ok {
    $diff = Text::Difference->new(
        a => "  one  blue two",
        b => "one two green",
        tokens => { colour => [ 'red', 'green', 'blue' ] },
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( $diff->match, "it's a match" );

ok( exists $diff->a_tokens_matched->{ colour }->{ blue }, "'blue' was found in a" );
ok( exists $diff->b_tokens_matched->{ colour }->{ green }, "'green' was found in b" );

ok( keys %{ $diff->a_tokens_matched->{ colour } } == keys %{ $diff->b_tokens_matched->{ colour } }, "number of keys is the same" );

ok( keys %{ $diff->a_tokens_matched->{ colour } } == 1 && keys %{ $diff->b_tokens_matched->{ colour } } == 1, "number of keys is 1" );

#################

lives_ok {
    $diff = Text::Difference->new(
        a => "  one  blue two",
        b => "one dark brown two green",
        tokens => { colour => [ 'red', 'green', 'blue', 'dark brown' ] },
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( $diff->match, "it's a match" );

ok( exists $diff->a_tokens_matched->{ colour }->{ blue }, "'blue' was found in a" );
ok( exists $diff->b_tokens_matched->{ colour }->{ 'dark brown' }, "'dark brown' was found in b" );
ok( exists $diff->b_tokens_matched->{ colour }->{ green }, "'green' was found in b" );

ok( keys %{ $diff->a_tokens_matched->{ colour } } != keys %{ $diff->b_tokens_matched->{ colour } }, "number of keys is different" );

ok( keys %{ $diff->a_tokens_matched->{ colour } } == 1 && keys %{ $diff->b_tokens_matched->{ colour } } == 2, "number of keys in a is 1 and b is 2" );

#################

lives_ok {
    $diff = Text::Difference->new(
        a => "  small blue car",
        b => "orange car extra large",
        tokens => {
            colour => [ 'red', 'green', 'blue', 'dark brown', 'orange' ],
            size => [ 'small', 'medium', 'Large', 'EXtra Large' ],
        },
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( $diff->match, "it's a match" );

ok( exists $diff->a_tokens_matched->{ colour }->{ blue }, "'blue' was found in a" );
ok( exists $diff->b_tokens_matched->{ colour }->{ orange }, "'orange' was found in b" );

ok( exists $diff->a_tokens_matched->{ size }->{ small }, "'small' was found in a" );
ok( exists $diff->b_tokens_matched->{ size }->{ 'EXtra Large' }, "'EXtra Large' was found in b" );

ok( keys %{ $diff->a_tokens_matched->{ colour } } == keys %{ $diff->b_tokens_matched->{ colour } }, "number of keys is the same" );

ok( keys %{ $diff->a_tokens_matched->{ colour } } == 1 && keys %{ $diff->b_tokens_matched->{ colour } } == 1, "number of keys is 1" );

ok( keys %{ $diff->a_tokens_matched->{ size } } == keys %{ $diff->b_tokens_matched->{ size } }, "number of keys is the same" );

ok( keys %{ $diff->a_tokens_matched->{ size } } == 1 && keys %{ $diff->b_tokens_matched->{ size } } == 1, "number of keys is 1" );





done_testing();
