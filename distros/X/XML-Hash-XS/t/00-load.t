
use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('XML::Hash::XS') };

diag( "Testing XML::Hash::XS $XML::Hash::XS::VERSION, Perl $], $^X" );

eval { require XML::LibXML };
unless ($@) {
    diag("XML::LibXML $XML::LibXML::VERSION, libxml2 ", XML::LibXML::LIBXML_VERSION());
}
