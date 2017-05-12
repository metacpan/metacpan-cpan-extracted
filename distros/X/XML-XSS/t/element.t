use strict;
use warnings;

use Test::More 0.94;

use XML::XSS;

my $xss = XML::XSS->new;

$xss->set( 'foo' => {
       pre => 'PRE',
       post => 'POST',
} );

is $xss->element( 'foo' )->pre->value => 'PRE', 'element PRE';

is $xss->render( '<doc><foo>bar</foo></doc>' ) 
    =>  "<doc>PREbarPOST</doc>" ;


done_testing;
