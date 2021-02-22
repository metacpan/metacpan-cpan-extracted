use strict;
use warnings;

use Test::More;

my $class = 'Text::Lorem';
use_ok($class);

SCALAR_CONTEXT: {
    note( 'scalar context' );

    my $object = $class->new();
    my $paragraphs = $object->paragraphs(3);
    is( split( /\n\n/, $paragraphs ), 3, 'string contains the expected number of paragraphs' );
}

LIST_CONTEXT: {
    note( 'list context' );

    my $object = $class->new();
    my @paragraphs = $object->paragraphs(3);
    is( @paragraphs, 3, 'array contains the expected number of paragraphs' );
}

done_testing();
