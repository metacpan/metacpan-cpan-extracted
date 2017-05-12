use strict;
use warnings;

use Test::More;
use Test::Exception;

use Text::Difference;

my $diff = undef;

lives_ok {
    $diff = Text::Difference->new(
        a => "  one   two three",
        b => "one two",
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( ! $diff->match, "it's not a match" );

ok( exists $diff->a_tokens_remaining->{ three }, "'three' is still remaining in a" );

#################

lives_ok {
    $diff = Text::Difference->new(
        a => "    one",
        b => " one   (two) ",
        stopwords => [ '(', ')' ],
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( ! $diff->match, "it's not a match" );

ok( exists $diff->b_tokens_remaining->{ two }, "'two' is still remaining in b" );

#################

lives_ok {
    $diff = Text::Difference->new(
        a => "    one",
        b => " one   two  one ",
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( ! $diff->match, "it's not a match" );

ok( ! exists $diff->a_tokens_remaining->{ one }, "'one' is not remaining in a" );
ok( exists $diff->b_tokens_remaining->{ two }, "'two' is still remaining in b" );
ok( ! exists $diff->b_tokens_remaining->{ one }, "'one' is not remaining in b" );

#################

lives_ok {
    $diff = Text::Difference->new(
        a => "one two five two two one two",
        b => "five two",
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( ! $diff->match, "it's not a match" );

ok( exists $diff->a_tokens_remaining->{ one }, "'one' is still remaining in a" );
ok( $diff->a_tokens_remaining->{ one } == 2, "there's 2 'one's is still remaining in a" );

ok( ! exists $diff->a_tokens_remaining->{ two }, "'two' is not remaining in a" );

ok( ! exists $diff->b_tokens_remaining->{ two }, "'two' is not remaining in b" );

ok( ! exists $diff->a_tokens_remaining->{ five }, "'five' is not remaining in a" );
ok( ! exists $diff->b_tokens_remaining->{ five }, "'five' is not remaining in b" );








done_testing();
