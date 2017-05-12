use Test::More tests => 55;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa id="a1">
		<xxx id="x1">
			<ddd id="d1">
				<bbb id="b1" />
				<bbb id="b2" />
				<eee id="e1" />
				<fff id="f1" />
			</ddd>
		</xxx>
		<ccc id="c1">
			<ddd id="d2">
				<bbb id="b3" />
				<bbb id="b4" />
				<eee id="e2" />
				<fff id="f2" />
			</ddd>
		</ccc>
		<ccc id="c2">
			<bbb id="b5">
				<bbb id="b6">
					<bbb id="b7" />
				</bbb>
			</bbb>
		</ccc>
	</aaa>
!);

test_nodeset(
	'/aaa/ccc/ddd/*',
	[
		{'nodename' => 'bbb', 'id' => 'b3'},
		{'nodename' => 'bbb', 'id' => 'b4'},
		{'nodename' => 'eee', 'id' => 'e2'},
		{'nodename' => 'fff', 'id' => 'f2'},
	]
);

test_nodeset(
	'*/*/*/bbb',
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'bbb', 'id' => 'b2'},
		{'nodename' => 'bbb', 'id' => 'b3'},
		{'nodename' => 'bbb', 'id' => 'b4'},
		{'nodename' => 'bbb', 'id' => 'b6'},
	]
);

test_nodeset(
	'//*',
	[
		{'nodename' => 'aaa', 'id' => 'a1'},
		{'nodename' => 'xxx', 'id' => 'x1'},
		{'nodename' => 'ddd', 'id' => 'd1'},
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'bbb', 'id' => 'b2'},
		{'nodename' => 'eee', 'id' => 'e1'},
		{'nodename' => 'fff', 'id' => 'f1'},
		{'nodename' => 'ccc', 'id' => 'c1'},
		{'nodename' => 'ddd', 'id' => 'd2'},
		{'nodename' => 'bbb', 'id' => 'b3'},
		{'nodename' => 'bbb', 'id' => 'b4'},
		{'nodename' => 'eee', 'id' => 'e2'},
		{'nodename' => 'fff', 'id' => 'f2'},
		{'nodename' => 'ccc', 'id' => 'c2'},
		{'nodename' => 'bbb', 'id' => 'b5'},
		{'nodename' => 'bbb', 'id' => 'b6'},
		{'nodename' => 'bbb', 'id' => 'b7'},
	]
);
