use Test::More tests => 2;

use strict;
use lib 'lib';
use XML::Parser::Lite::Tree::XPath::Axis;


#
# 
#

my $axis = XML::Parser::Lite::Tree::XPath::Axis->instance();

my $ret = $axis->filter({axis => 'fake'}, 'context');

is($ret->{type}, 'Error', "Error returned from bad axis");
like($ret->{value}, qr/Unknown axis/, "Correct error message from bas axis");

