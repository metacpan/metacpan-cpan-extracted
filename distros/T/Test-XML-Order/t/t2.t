# @(#) $Id$
use strict;
use warnings;

use Test::More tests => 2;
use Test::XML::Order;

is_xml_in_order( '<foo /><foo />', '<foo></foo><foo x="a"/>' );   # PASS
isnt_xml_in_order( '<foo /><bar />', '<bar /><foo />' );     # PASS

