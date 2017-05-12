use strict;
use warnings;

use Test::More;
use Test::Exception;

use Text::Difference;

my $diff = undef;

####################################
# perfect match with empty strings #
####################################

lives_ok {
    $diff = Text::Difference->new(
        a => "",
        b => "",
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( $diff->match, "it's a match" );

#################
# perfect match #
#################

lives_ok {
    $diff = Text::Difference->new(
        a => "one two three",
        b => "one two three",
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( $diff->match, "it's a match" );

################
# exact tokens #
################

lives_ok {
    $diff = Text::Difference->new(
        a => "one two three",
        b => "three one two",
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( $diff->match, "it's a match" );

####################
# not exact tokens #
####################

lives_ok {
    $diff = Text::Difference->new(
        a => "one two three",
        b => "four one two",
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( ! $diff->match, "it's not a match" );

#############
# and again #
#############

lives_ok {
    $diff = Text::Difference->new(
        a => "",
        b => "one",
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( ! $diff->match, "it's not a match" );

#############
# stopwords #
#############

lives_ok {
    $diff = Text::Difference->new(
        a => "foo, bar",
        b => "bar - foo",
        stopwords => [ ',', '-' ],
        debug => 0,
    );
} "instantiated with options ok";

lives_ok {
    $diff->check;
} "called check() ok";

ok( $diff->match, "it's a match" );


done_testing();
