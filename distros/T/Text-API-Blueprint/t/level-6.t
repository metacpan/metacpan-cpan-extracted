#!perl

use t::tests;
use Text::API::Blueprint qw(Action);

use constant EOL => "\n";

plan tests => 14;

################################################################################

tdt( Action( { map { $_ => $_ } qw(method) } ), <<'EOT', 'Action' );
### method

EOT

################################################################################

tdt( Action( { map { $_ => $_ } qw(method description) } ), <<'EOT', 'Action' );
### method

description

EOT

################################################################################

tdt(
    Action(
        {
            ( map { $_ => $_ } qw(method) ), description => [qw[foo bar baz]],
        }
    ),
    <<'EOT', 'Action' );
### method

foo

bar

baz

EOT

################################################################################

tdt( Action( { map { $_ => $_ } qw(method identifier) } ),
    <<'EOT', 'Action identifier' );
### identifier [method]

EOT

################################################################################

tdt( Action( { map { $_ => $_ } qw(method identifier uri) } ),
    <<'EOT', 'Action identifier uri' );
### identifier [method uri]

EOT

################################################################################

tdt( Action( { map { $_ => $_ } qw(method relation) } ),
    <<'EOT', 'Action relation' );
### method

+ Relation: relation

EOT

################################################################################

tdt(
    Action(
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
            map { $_ => $_ } qw(method)
        }
    ),
    <<'EOT', 'Action paramters' );
### method

+ Parameters

    + foo: `example` (enum[enum], required) - shortdesc
    
        longdesc
        
        + Default: `default`
        
        + Members
        
            + `bar` - baz

EOT

################################################################################

tdt(
    Action(
        {
            requests => [
                identifier => {
                    type        => 'type',
                    description => 'description',
                    headers     => [ foo => 'bar' ],
                    code        => 'code',
                    lang        => 'lang',
                    schema      => "schema",
                }
            ],
            map { $_ => $_ } qw(method)
        }
    ),
    <<'EOT', 'Action request(single)' );
### method

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
    Action(
        {
            requests => [qw[ foo1 bar1 foo2 bar2 ]],
            map { $_ => $_ } qw(method)
        }
    ),
    <<'EOT', 'Action requests' );
### method

+ Request foo1

    [bar1][]

+ Request foo2

    [bar2][]

EOT

################################################################################

tdt(
    Action(
        {
            responses => [
                identifier => {
                    type        => 'type',
                    description => 'description',
                    headers     => [ foo => 'bar' ],
                    code        => 'code',
                    lang        => 'lang',
                    schema      => "schema",
                },
            ],
            map { $_ => $_ } qw(method)
        }
    ),
    <<'EOT', 'Action response(single)' );
### method

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

tdt(
    Action(
        {
            responses => [qw[ foo1 bar1 foo2 bar2 ]],
            map { $_ => $_ } qw(method)
        }
    ),
    <<'EOT', 'Action responses' );
### method

+ Response foo1

    [bar1][]

+ Response foo2

    [bar2][]

EOT

################################################################################

tdt(
    Action(
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
            map { $_ => $_ } qw(method)
        }
    ),
    <<'EOT', 'Action responses' );
### method

+ Attributes

    + a: `b` (c) - d
    + e: `f` (g) - h

EOT

################################################################################

tdt(
    Action(
        {
            requests => [
                identifier => {
                    type        => 'type',
                    description => 'description',
                    headers     => [ foo => 'bar' ],
                    code        => 'code',
                    lang        => 'lang',
                    schema      => "schema",
                }
            ],
            responses => [
                identifier => {
                    type        => 'type',
                    description => 'description',
                    headers     => [ foo => 'bar' ],
                    code        => 'code',
                    lang        => 'lang',
                    schema      => "schema",
                },
            ],
            map { $_ => $_ } qw(method)
        }
    ),
    <<'EOT', 'Action response(single)' );
### method

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

tdt(
    Action(
        {
            assets => [
                'Request identifier' => {
                    type        => 'type',
                    description => 'description',
                    headers     => [ foo => 'bar' ],
                    code        => 'code',
                    lang        => 'lang',
                    schema      => "schema",
                },
                'Response identifier' => {
                    type        => 'type',
                    description => 'description',
                    headers     => [ foo => 'bar' ],
                    code        => 'code',
                    lang        => 'lang',
                    schema      => "schema",
                },
            ],
            map { $_ => $_ } qw(method)
        }
    ),
    <<'EOT', 'Action response(single)' );
### method

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
