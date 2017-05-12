use Test::More tests => 17;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa id="a1">
		<bbb id="b1" />
		<bbb id="b2" />
		<bbb id="b3" />
		<bbb id="b4" />
		<bbb id="b5" />
		<bbb id="b6" />
		<bbb id="b7" />
		<bbb id="b8" />
		<ccc id="c1" />
		<ccc id="c2" />
		<ccc id="c3" />
	</aaa>
!);

test_nodeset(
	'//bbb[position() mod 2 = 0 ]',
	[
		{'nodename' => 'bbb', 'id' => 'b2'},
		{'nodename' => 'bbb', 'id' => 'b4'},
		{'nodename' => 'bbb', 'id' => 'b6'},
		{'nodename' => 'bbb', 'id' => 'b8'},
	]
);

test_nodeset(
	'//bbb[ position() = floor(last() div 2 + 0.5) or position() = ceiling(last() div 2 + 0.5) ]',
	[
		{'nodename' => 'bbb', 'id' => 'b4'},
		{'nodename' => 'bbb', 'id' => 'b5'},
	]
);

test_nodeset(
	'//ccc[ position() = floor(last() div 2 + 0.5) or position() = ceiling(last() div 2 + 0.5) ]',
	[
		{'nodename' => 'ccc', 'id' => 'c2'},
	]
);
