use Test::More tests => 30;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa id="a1">
		<bbb id="b1">
			<ccc id="c1" />
			<zzz id="z1">
				<ddd id="d1" />
				<ddd id="d2">
					<eee id="e1" />
				</ddd>
			</zzz>
			<fff id="f1">
				<ggg id="g1" />
			</fff>
		</bbb>
		<xxx id="x1">
			<ddd id="d3">
				<eee id="e2" />
				<ddd id="d4" />
				<ccc id="c2" />
				<fff id="f2" />
				<fff id="f3">
					<ggg id="g2" />
				</fff>
			</ddd>
		</xxx>
		<ccc id="c3">
			<ddd id="d5" />
		</ccc>
	</aaa>
!);

test_nodeset(
	'/aaa/xxx/following::*',
	[
		{'nodename' => 'ccc', 'id' => 'c3'},
		{'nodename' => 'ddd', 'id' => 'd5'},
	]
);

test_nodeset(
	'//zzz/following::*',
	[
		{'nodename' => 'fff', 'id' => 'f1'},
		{'nodename' => 'ggg', 'id' => 'g1'},
		{'nodename' => 'xxx', 'id' => 'x1'},
		{'nodename' => 'ddd', 'id' => 'd3'},
		{'nodename' => 'eee', 'id' => 'e2'},
		{'nodename' => 'ddd', 'id' => 'd4'},
		{'nodename' => 'ccc', 'id' => 'c2'},
		{'nodename' => 'fff', 'id' => 'f2'},
		{'nodename' => 'fff', 'id' => 'f3'},
		{'nodename' => 'ggg', 'id' => 'g2'},
		{'nodename' => 'ccc', 'id' => 'c3'},
		{'nodename' => 'ddd', 'id' => 'd5'},
	]
);
