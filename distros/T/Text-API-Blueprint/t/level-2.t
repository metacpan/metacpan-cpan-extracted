#!perl

use t::tests;
use Text::API::Blueprint qw(Parameters Body_YAML Body_JSON Group);

use constant EOL => "\n";

plan tests => 4;

################################################################################

tdt(
    Parameters(
        [
            foo => {
                (
                    map { ( $_ => $_ ) }
                      qw(example required type enum shortdesc longdesc default)
                ),
                members => [
                    foo => 'foof',
                    bar => 'barf',
                ]
            },
            bar => {
                (
                    map { ( $_ => $_ ) }
                      qw(example required type enum shortdesc longdesc default)
                ),
                members => [
                    foo => 'foof',
                    bar => 'barf',
                ]
            },
        ]
    ),
    <<EOT, 'Parameters' );
+ Parameters

    + foo: `example` (enum[enum], required) - shortdesc
    
        longdesc
        
        + Default: `default`
        
        + Members
        
            + `foo` - foof
            + `bar` - barf
    
    + bar: `example` (enum[enum], required) - shortdesc
    
        longdesc
        
        + Default: `default`
        
        + Members
        
            + `foo` - foof
            + `bar` - barf
    
    

EOT

################################################################################

SKIP: {
    skip "YAML/JSON" => 2 unless $ENV{AUTHOR_TESTING};

################################################################################

    tdt( Body_YAML( [ {qw(a b)}, {qw(c d)} ] ), <<EOT, 'Body_YAML' );
+ Body

    ```yaml
    ---
    - a: b
    - c: d
    
    ```
    
    

EOT

################################################################################

    tdt( Body_JSON( [ {qw(a b)}, {qw(c d)} ] ), <<EOT, 'Body_YAML' );
+ Body

    ```json
    [
       {
          "a" : "b"
       },
       {
          "c" : "d"
       }
    ]
    
    ```
    
    

EOT

################################################################################

}

################################################################################

tdt( Group( 'foo', 'bar' ), <<EOT, 'Group' );
# Group foo

bar

EOT

################################################################################

done_testing;
