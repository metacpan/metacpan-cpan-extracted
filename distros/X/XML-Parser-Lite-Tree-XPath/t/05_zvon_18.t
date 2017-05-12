use Test::More tests => 26;

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
			</zzz>
		</bbb>
		<xxx id="x1">
			<ddd id="d2">
				<eee id="e1" />
				<ddd id="d3" />
				<ccc id="c2" />
				<fff id="f1" />
				<fff id="f2">
					<ggg id="g1" />
				</fff>
			</ddd>
		</xxx>
		<ccc id="c3">
			<ddd id="d4" />
		</ccc>
	</aaa>
!);

test_nodeset(
	'/aaa/xxx/preceding::*',
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'ccc', 'id' => 'c1'},
		{'nodename' => 'zzz', 'id' => 'z1'},
		{'nodename' => 'ddd', 'id' => 'd1'},
	]
);

test_nodeset(
	'//ggg/preceding::*',
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'ccc', 'id' => 'c1'},
		{'nodename' => 'zzz', 'id' => 'z1'},
		{'nodename' => 'ddd', 'id' => 'd1'},
		{'nodename' => 'eee', 'id' => 'e1'},
		{'nodename' => 'ddd', 'id' => 'd3'},
		{'nodename' => 'ccc', 'id' => 'c2'},
		{'nodename' => 'fff', 'id' => 'f1'},
	]
);
