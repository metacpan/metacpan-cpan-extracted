use Test::More tests => 18;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa>
		<bbb id="b1" />
		<ccc />
		<bbb id="b2" />
		<ddd>
			<bbb id="b3" />
		</ddd>
		<ccc>
			<ddd>
				<bbb id="b4" />
				<bbb id="b5" />
			</ddd>
		</ccc>
	</aaa>
!);

test_nodeset(
	'//bbb',
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'bbb', 'id' => 'b2'},
		{'nodename' => 'bbb', 'id' => 'b3'},
		{'nodename' => 'bbb', 'id' => 'b4'},
		{'nodename' => 'bbb', 'id' => 'b5'},
	]
);

test_nodeset(
	'//ddd/bbb',
	[
		{'nodename' => 'bbb', 'id' => 'b3'},
		{'nodename' => 'bbb', 'id' => 'b4'},
		{'nodename' => 'bbb', 'id' => 'b5'},
	]
);
