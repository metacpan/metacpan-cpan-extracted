# @(#) $Id$
use strict;
use warnings;

use Test::More tests => 4;

require Test::XML::Order;

my $data = 'x';

eval {
    Test::XML::Order::is_xml_in_order('a');
};
like($@, qr/usage: is_xml_in_order\(input,expected,test_name\)/);
eval {
    Test::XML::Order::isnt_xml_in_order('b');
};
like($@, qr/usage: isnt_xml_in_order\(input,expected,test_name\)/);
eval {
    Test::XML::Order::is_xml_in_order();
};
like($@, qr/usage: is_xml_in_order\(input,expected,test_name\)/);
eval {
    Test::XML::Order::isnt_xml_in_order();
};
like($@, qr/usage: isnt_xml_in_order\(input,expected,test_name\)/);
