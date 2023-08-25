#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use UML::PlantUML::Encoder qw(encode_p);

my $encoded = encode_p(
    qq{
Alice -> Bob: Authentication Request
Bob --> Alice: Authentication Response
}
);

#diag $encoded;

ok( $encoded eq
        '~169NZSip9J4vLqBLJSCfFib9mB2t9ICqhoKnEBCdCprC8IYqiJIqkuGBAAUW2rO0LOr5LN92VLvpA1G3PV1em',
    'Encoding works'
);
