use strict;
use warnings;

use Test::More tests => 2;

use URI::Template ':all';

ok (
    template_process( "http://my.host.com/{user}",
        user => "vanHoesel",
    )->path
    eq
    "/vanHoesel",
    "template_process creates the right URI object"
);

ok (
    template_process_to_string( "http://my.host.com/{user}",
        user => "vanHoesel",
    )
    eq
    "http://my.host.com/vanHoesel",
    "template_process_to_string creates the right string"
);


done_testing();

1;
