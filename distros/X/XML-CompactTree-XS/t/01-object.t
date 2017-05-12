
use Test::More tests => 2;
use strict;
use warnings;
BEGIN {
use_ok( 'XML::CompactTree::XS' );
use_ok( 'XML::LibXML::Reader' );
import XML::CompactTree::XS;
}

