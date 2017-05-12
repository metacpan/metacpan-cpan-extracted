use strict;
use warnings;

use Test::More tests => 2;                      # last test to print

use XML::XPathScript;

my $xps = XML::XPathScript->new;

# can we set arguments?
$xps->set_xml( '<doc></doc>' );
$xps->set_stylesheet( '<%= $foo . ":" . $bar %>' );
$xps->compile( qw/ $foo $bar / );
is $xps->transform( undef, undef, [ 'un', 'deux' ] ), 'un:deux';

# access them via @_?
$xps->set_stylesheet( '<%= join ":", @_[1,2] %>' );

is $xps->transform( undef, undef, [ 'trois', 'quatre' ] ),
    'trois:quatre';







