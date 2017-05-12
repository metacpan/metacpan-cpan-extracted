use Test::More tests => 21;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa id="a1">
		<bbb id="b1" />
		<ccc id="c1" />
		<ddd id="d1">
			<ccc id="c2" />
		</ddd>
		<eee id="e1" />
	</aaa>
!);

test_nodeset(
	'//ccc | //bbb',
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'ccc', 'id' => 'c1'},
		{'nodename' => 'ccc', 'id' => 'c2'},
	]
);

test_nodeset(
	'/aaa/eee | //bbb',
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'eee', 'id' => 'e1'},
	]
);

test_nodeset(
	'/aaa/eee | //ddd/ccc | /aaa | //bbb',
	[
		{'nodename' => 'aaa', 'id' => 'a1'},
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'ccc', 'id' => 'c2'},
		{'nodename' => 'eee', 'id' => 'e1'},
	]
);
