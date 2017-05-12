#!perl

use t::tests;
use Text::API::Blueprint qw(Resource);

use constant EOL => "\n";

plan tests => 9;

################################################################################

tdt( Resource( { map { $_ => $_ } qw(uri) } ), <<'EOT', 'Request uri' );
## uri

EOT

################################################################################

tdt( Resource( { map { $_ => $_ } qw(identifier uri) } ),
    <<'EOT', 'Request identifier uri' );
## identifier [uri]

EOT

################################################################################

tdt( Resource( { map { $_ => $_ } qw(method uri) } ),
    <<'EOT', 'Request method uri' );
## method uri

EOT

################################################################################

tdt( Resource( { map { $_ => $_ } qw(uri description) } ),
    <<'EOT', 'Request description' );
## uri

description

EOT

################################################################################

tdt(
    Resource(
        {
            ( map { $_ => $_ } qw(uri) ), description => [qw[foo bar baz]],
        }
    ),
    <<'EOT', 'Request description' );
## uri

foo

bar

baz

EOT

################################################################################

tdt(
    Resource(
        {
            parameters => [
                foo => {
                    (
                        map { ( $_ => $_ ) }
                          qw(example required type enum shortdesc longdesc default)
                    ),
                    members => [
                        bar => 'baz',
                    ]
                },
            ],
            map { $_ => $_ } qw(uri)
        }
    ),
    <<'EOT', 'Request parameters' );
## uri

+ Parameters

    + foo: `example` (enum[enum], required) - shortdesc
    
        longdesc
        
        + Default: `default`
        
        + Members
        
            + `bar` - baz

EOT

################################################################################

tdt(
    Resource(
        {
            model => {
                type        => 'type',
                description => 'description',
                headers     => [ foo => 'bar' ],
                code        => 'code',
                lang        => 'lang',
                schema      => "schema",
            },
            map { $_ => $_ } qw(uri)
        }
    ),
    <<'EOT', 'Request model' );
## uri

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
    Resource(
        {
            actions => [
                {
                    method => 'foo'
                },
                {
                    method => 'bar'
                }
            ],
            map { $_ => $_ } qw(uri)
        }
    ),
    <<'EOT', 'Request action' );
## uri

### foo

### bar

EOT

################################################################################

tdt(
    Resource(
        {
            attributes => [
                a => {
                    example     => 'b',
                    type        => 'c',
                    description => 'd'
                },
                e => {
                    example     => 'f',
                    type        => 'g',
                    description => 'h'
                },
            ],
            map { $_ => $_ } qw(uri)
        }
    ),
    <<'EOT', 'Request attributes' );
## uri

+ Attributes

    + a: `b` (c) - d
    + e: `f` (g) - h

EOT

################################################################################

done_testing;
