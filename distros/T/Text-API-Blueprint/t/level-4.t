#!perl

use t::tests;
use Text::API::Blueprint qw(Model Asset);

use constant EOL => "\n";

plan tests => 4;

################################################################################

tdt(
    Model(
        {
            type        => 'type',
            description => 'description',
            headers     => [ foo => 'bar' ],
            code        => 'code',
            lang        => 'lang',
            schema      => "schema",
        }
    ),
    <<'EOT', 'Model (1)' );
+ Model (type)

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
    Model(
        'type',
        {
            description => 'description',
            headers     => [ foo => 'bar' ],
            code        => 'code',
            lang        => 'lang',
            schema      => "schema",
        }
    ),
    <<'EOT', 'Model (2)' );
+ Model (type)

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

tdt( Model( 'type', 'payload' ), <<'EOT', 'Model (3)' );
+ Model (type)

    payload

EOT

################################################################################

tdt(
    Asset(
        keyword => 'identifier',
        {
            type        => 'type',
            description => 'description',
            headers     => [ foo => 'bar' ],
            code        => 'code',
            lang        => 'lang',
            schema      => "schema",
        }
    ),
    <<'EOT', 'Asset' );
+ keyword identifier (type)

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
