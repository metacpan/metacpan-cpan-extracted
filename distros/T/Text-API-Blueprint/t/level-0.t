#!perl

use t::tests;
use Text::API::Blueprint
  qw(Meta Intro Concat Code Schema Attributes Reference Headers Body Relation);

plan tests => 13;

################################################################################

tdt( Meta('localhost') => <<EOT, 'Meta' );
FORMAT: 1A8
HOST: localhost

EOT

################################################################################

tdt( Intro( 'foo', 'bar' ) => <<EOT, 'Intro' );
# foo

bar

EOT

################################################################################

tdt( Intro( 'foo', [ 'bar', 'baz' ] ) => <<EOT, 'Intro' );
# foo

bar

baz

EOT

################################################################################

tdt( Concat( '   foo   ', "\nbar\n", "" ) => <<EOT, 'Concat' );
foo

bar

EOT

################################################################################

pass('self-defined amount of delimiters is now deprecated');

################################################################################

tdt( Code('a`b``c```d````e`````f```````h') => <<EOT, 'Code' );
````````
a`b``c```d````e`````f```````h
````````

EOT

################################################################################

tdt( Schema( 'foo', 8 ) => <<EOT, 'Schema' );
+ Schema

        foo

EOT

################################################################################

tdt( Attributes('foo') => <<EOT, 'Attributes (1)' );
+ Attributes (foo)

EOT

################################################################################

tdt(
    Attributes(
        [
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
            i => [
                j => {
                    example     => 'k',
                    type        => 'l',
                    description => 'm',
                },
                n => [
                    o => {
                        example     => 'p',
                        type        => 'q',
                        description => 'r',
                    }
                ]
            ]
        ],
        3
    ) => <<EOT, 'Attributes (2)' );
+ Attributes

   + a: `b` (c) - d
   + e: `f` (g) - h
   + i
       + j: `k` (l) - m
       + n
           + o: `p` (q) - r

EOT

################################################################################

tdt( Reference( 'foo', 'bar', 'baz' ) => <<EOT, 'Reference' );
+ foo bar

    [baz][]

EOT

################################################################################

tdt(
    Headers(
        [
            'foo'       => 1,
            '-foo'      => 2,
            'FooBarBaz' => 3,
        ]
    ) => <<EOT, 'Headers' );
+ Headers

        Foo: 1
        X-Foo: 2
        Foo-Bar-Baz: 3

EOT

################################################################################

tdt( Body("\n\n   foo   \nbar\n\nbaz") => <<EOT, 'Body' );
+ Body

        foo   
        bar
        
        baz

EOT

################################################################################

tdt( Relation('foobar') => <<EOT, 'Relation' );
+ Relation: foobar

EOT

################################################################################

done_testing;
