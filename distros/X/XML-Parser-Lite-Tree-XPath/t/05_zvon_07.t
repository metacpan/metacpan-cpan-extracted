use Test::More tests => 13;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa id="a1">
		<ccc id="c1">
			<bbb />
			<bbb />
			<bbb />
		</ccc>
		<ddd id="d1">
			<bbb />
			<bbb />
		</ddd>
		<eee id="e1">
			<ccc id="c2" />
			<ddd id="d2" />
		</eee>
	</aaa>
!);

test_nodeset(
	'//*[count(bbb)=2]',
	[
		{'nodename' => 'ddd', 'id' => 'd1'},
	]
);

test_nodeset(
	'//*[count(*)=2]',
	[
		{'nodename' => 'ddd', 'id' => 'd1'},
		{'nodename' => 'eee', 'id' => 'e1'},
	]
);

test_nodeset(
	'//*[count(*)=3]',
	[
		{'nodename' => 'aaa', 'id' => 'a1'},
		{'nodename' => 'ccc', 'id' => 'c1'},
	]
);
