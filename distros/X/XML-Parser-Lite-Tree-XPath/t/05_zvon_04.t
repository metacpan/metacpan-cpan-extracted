use Test::More tests => 6;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa>
		<bbb id="b1" />
		<bbb id="b2" />
		<bbb id="b3" />
		<bbb id="b4" />
	</aaa>
!);

test_nodeset(
	'/aaa/bbb[1]',
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
	]
);

test_nodeset(
	'/aaa/bbb[last()]',
	[
		{'nodename' => 'bbb', 'id' => 'b4'},
	]
);
