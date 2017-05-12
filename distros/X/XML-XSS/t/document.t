
use strict;
use warnings;

use Test::More 0.94;

use XML::XSS;

my $xss = XML::XSS->new;

$xss->set( '#document' => {
       pre => 'PRE',
       post => 'POST',
} );

is $xss->render( '<doc><foo>bar</foo></doc>' ) 
    =>  "PRE<doc><foo>bar</foo></doc>POST" ;

$xss->set( '#document' => {
    content => 'INNER',
} );

is $xss->render( '<doc><foo>bar</foo></doc>' ) 
    =>  "PREINNERPOST" ;


done_testing;
