use Test::More tests => 11;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa id="a1">
		<bbb id="b1" />
		<ccc id="c1" />
		<bbb id="b2" />
		<ddd>
			<bbb id="b3" />
		</ddd>
		<ccc id="c2" />
	</aaa>
!);

test_nodeset(
	'/aaa',
	[
		{'nodename' => 'aaa', 'id' => 'a1'},
	]
);

test_nodeset(
	'/aaa/ccc',
	[
		{'nodename' => 'ccc', 'id' => 'c1'},
		{'nodename' => 'ccc', 'id' => 'c2'},
	]
);

test_nodeset(
	'/aaa/ddd/bbb',
	[
		{'nodename' => 'bbb', 'id' => 'b3'},
	]
);
