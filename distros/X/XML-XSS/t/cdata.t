use strict;
use warnings;

use Test::More 0.94;

use XML::XSS;

my $xss = XML::XSS->new;

$xss->set( '#text' => {
        filter => sub { s/boo/yay/; $_ },
} );

is $xss->render( '<doc><![CDATA[ boo ]]></doc>' )
    =>  "<doc> yay </doc>" ;


done_testing;
