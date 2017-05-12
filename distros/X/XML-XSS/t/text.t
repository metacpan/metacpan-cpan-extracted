use strict;
use warnings;

use Test::More 0.94;

use XML::XSS;

my $xss = XML::XSS->new;

is $xss->render( '<doc>hello?</doc>' ) => '<doc>hello?</doc>';

$xss->set_text(
        filter => sub { uc },
        pre => 'A',
        post => 'Z',
);

is $xss->render( '<doc>hello?</doc>' ) => '<doc>AHELLO?Z</doc>';

$xss->clear_text;
$xss->set_text(
    'replace' => 'BYE',
);

is $xss->render( '<doc>hello?</doc>' ) => '<doc>BYE</doc>';

$xss->clear_text;
$xss->set_text(
    replace => sub { join ' - ', ref $_[1], ref $_[0] , $_[2]->{boo};
    },
);

is $xss->render( '<doc>hello?</doc>', {boo => 'yah' } ) 
    => '<doc>XML::LibXML::Text - XML::XSS::Text - yah</doc>';

$xss->set_text(
    process => 0,
);

is $xss->render( '<doc>hello?</doc>' ) => '<doc></doc>';


done_testing;

