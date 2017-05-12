#!perl

use t::tests;
use Text::API::Blueprint qw(Text Body_CODE Request_Ref Response_Ref Parameter);

use constant EOL => "\n";

plan tests => 6;

################################################################################

tdt( Text(qw(a b c)) . EOL, <<EOT, 'Text' );
a

b

c
EOT

################################################################################

tdt( Body_CODE('foo') => <<EOT, 'Body_CODE (1)' );
+ Body

    ```
    foo
    ```
    
    

EOT

################################################################################

tdt( Body_CODE( 'foo', 'bar' ) => <<EOT, 'Body_CODE (2)' );
+ Body

    ```bar
    foo
    ```
    
    

EOT

################################################################################

tdt( Request_Ref( 'foo', 'bar' ) => <<EOT, 'Request_Ref' );
+ Request foo

    [bar][]

EOT

################################################################################

tdt( Response_Ref( 'foo', 'bar' ) => <<EOT, 'Response_Ref' );
+ Response foo

    [bar][]

EOT

################################################################################

tdt(
    Parameter(
        'foo',
        {
            (
                map { ( $_ => $_ ) }
                  qw(example required type enum shortdesc longdesc default)
            ),
            members => [
                foo => 'foof',
                bar => 'barf',
            ]
        }
    ) => <<EOT, 'Parameter' );
+ foo: `example` (enum[enum], required) - shortdesc

    longdesc
    
    + Default: `default`
    
    + Members
    
        + `foo` - foof
        + `bar` - barf

EOT

################################################################################

done_testing;
