#!perl

use t::tests;
use Text::API::Blueprint qw(Request Response);

use constant EOL => "\n";

plan tests => 2;

################################################################################

tdt(
    Request(
        'identifier',
        {
            type        => 'type',
            description => 'description',
            headers     => [ foo => 'bar' ],
            code        => 'code',
            lang        => 'lang',
            schema      => "schema",
        }
    ),
    <<'EOT', 'Request' );
+ Request identifier (type)

    description
    
    + Headers
    
            Foo: bar
    
    + Body
    
        ```lang
        code
        ```
    
    + Schema
    
        schema

EOT

################################################################################

tdt(
    Response(
        'identifier',
        {
            type        => 'type',
            description => 'description',
            headers     => [ foo => 'bar' ],
            code        => 'code',
            lang        => 'lang',
            schema      => "schema",
        }
    ),
    <<'EOT', 'Response' );
+ Response identifier (type)

    description
    
    + Headers
    
            Foo: bar
    
    + Body
    
        ```lang
        code
        ```
    
    + Schema
    
        schema

EOT

################################################################################

done_testing;
