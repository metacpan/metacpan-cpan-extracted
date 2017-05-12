use strict;
use warnings;

use Test::More;

use XML::XSS;

my $xss = XML::XSS->new;

$xss->set( doc => { content => xsst <<'END', } );
\<%= 'stuff' %>
END

is $xss->render('<doc>foo</doc>'), "\\stuff\n", 'final slash';

done_testing;
