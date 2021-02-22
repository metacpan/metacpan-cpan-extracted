use strict;
use warnings;

use Test::More;

my $class = 'Text::Lorem';
use_ok($class);

SCALAR_CONTEXT: {
    note( 'scalar context' );

    my $object = $class->new();
    my $words = $object->words(3);
    is( split( /\s+/, $words ), 3, 'string contains the expected number of words' );
}

LIST_CONTEXT: {
    note( 'list context' );

    my $object = $class->new();
    my @words = $object->words(3);
    is( @words, 3, 'array contains the expected number of words' );
}

done_testing();
