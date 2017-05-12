use strict;
use warnings;

use Test::More;  
use XML::XPathScript;

plan eval { require B::XPath; 1 } 
     ? ( tests => 1 )
     : ( skip_all => 'B::XPath not installed' );

sub guinea_pig {
    my $x = shift;
    my $y = time;
    print "oink oink " x $x;
    return $x * $y;
}

my $node = B::XPath->fetch_root( \&guinea_pig );

my $xps = XML::XPathScript->new;
$xps->set_dom( $node );
$xps->set_stylesheet( '<%~ //print %>' );

my $transformed = $xps->transform;

ok length( $transformed ) => 'grepping <print>';




