use strict;
use warnings;

use Test::More;
use Test::Exception;

use Text::Difference;

my $diff = undef;

lives_ok {
    $diff = Text::Difference->new(
        a => "  one   two three",
        b => "one two     three",
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( $diff->match, "it's a match" );

#################

lives_ok {
    $diff = Text::Difference->new(
        a => "two    one   ",
        b => " one - two",
        stopwords => [ ' - ' ],
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( $diff->match, "it's a match" );

################

lives_ok {
    $diff = Text::Difference->new(
        a => "     one    ",
        b => "one",
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( $diff->match, "it's a match" );


done_testing();
