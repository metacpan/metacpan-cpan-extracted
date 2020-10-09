#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Text::Sprintf::Named qw/ named_sprintf /;

{
    # TEST
    is(
        scalar( named_sprintf( 'Hello %(name)s!', { name => "Sophie", } ) ),
        'Hello Sophie!',
        q#named_sprintf works with a hash-ref as the parameters' container#,
    );
}

{
    # TEST
    is(
        scalar(
            named_sprintf(
                'Hello %(name)s! Are you from %(city)s?',
                city => "Lisbon",
                name => "Sophie",
            )
        ),
        'Hello Sophie! Are you from Lisbon?',
        'named_sprintf works with a flattened hash of arguments',
    );
}
