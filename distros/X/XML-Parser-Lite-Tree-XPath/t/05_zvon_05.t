use Test::More tests => 25;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa>
		<bbb id="b1" />
		<bbb id="b2" />
		<bbb name="bbb" />
		<bbb />
	</aaa>
!);

test_nodeset(
	'//@id',
	[
		{'nodename' => 'id', 'value' => 'b1', 'type' => 'attribute'},
		{'nodename' => 'id', 'value' => 'b2', 'type' => 'attribute'},
	]
);

test_nodeset(
	'//bbb[@id]',
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'bbb', 'id' => 'b2'},
	]
);

test_nodeset(
	'//bbb[@name]',
	[
		{'nodename' => 'bbb', 'name' => 'bbb'},
	]
);

test_nodeset(
	'//bbb[@*]',
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'bbb', 'id' => 'b2'},
		{'nodename' => 'bbb', 'name' => 'bbb'},
	]
);

test_nodeset(
	'//bbb[not(@*)]',
	[
		{'nodename' => 'bbb', 'attributecount' => 0},
	]
);
