use strict;
use warnings;

use Test::More;

my $class = 'Text::Lorem';
use_ok($class);

SCALAR_CONTEXT: {
    note( 'scalar context' );

    my $object = $class->new();
    my $sentences = $object->sentences(3);
    is( split( /\./, $sentences ), 3, 'string contains the expected number of sentences' );
}

LIST_CONTEXT: {
    note( 'list context' );

    my $object = $class->new();
    my @sentences = $object->sentences(3);
    is( @sentences, 3, 'array contains the expected number of sentences' );
}

done_testing();
