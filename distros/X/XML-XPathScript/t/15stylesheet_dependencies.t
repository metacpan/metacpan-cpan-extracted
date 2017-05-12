use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use XML::XPathScript;

my $xps = XML::XPathScript->new( xml => '<doc></doc>',
                                 stylesheetfile => 't/include2.xps' );

is join( ':', $xps->get_stylesheet_dependencies ) 
    => './t/include.xps:./t/include2.xps', 
    'get_stylesheet_dependendies()';


