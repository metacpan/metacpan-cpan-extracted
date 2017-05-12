use Test::More tests => 22;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa id="a1">
		<bbb id="b1">
			<ddd id="d1">
				<ccc id="c1">
					<ddd id="d2" />
					<eee id="e1" />
				</ccc>
			</ddd>
		</bbb>
		<ccc id="c2">
			<ddd id="d3">
				<eee id="e2">
					<ddd id="d4">
						<fff id="f1" />
					</ddd>
				</eee>
			</ddd>
		</ccc>
	</aaa>
!);

test_nodeset(
	'/aaa/bbb/ddd/ccc/eee/ancestor::*',
	[
		{'type' => 'root'},
		{'nodename' => 'aaa', 'id' => 'a1'},
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'ddd', 'id' => 'd1'},
		{'nodename' => 'ccc', 'id' => 'c1'},
	]
);

test_nodeset(
	'//fff/ancestor::*',
	[
		{'type' => 'root'},
		{'nodename' => 'aaa', 'id' => 'a1'},
		{'nodename' => 'ccc', 'id' => 'c2'},
		{'nodename' => 'ddd', 'id' => 'd3'},
		{'nodename' => 'eee', 'id' => 'e2'},
		{'nodename' => 'ddd', 'id' => 'd4'},
	]
);
