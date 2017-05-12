use Test::More tests => 72;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa id="a1">
		<bbb id="b1">
			<ccc id="c1" />
			<zzz id="z1" />
		</bbb>
		<xxx id="x1">
			<ddd id="d2">
				<eee id="e1" />
				<fff id="f1">
					<hhh id="h1" />
					<ggg id="g1">
						<jjj id="j1">
							<qqq id="q1" />
						</jjj>
						<jjj id="j2" />
					</ggg>
					<hhh id="h2" />
				</fff>
			</ddd>
		</xxx>
		<ccc id="c2">
			<ddd id="d3" />
		</ccc>
	</aaa>
!);

test_nodeset(
	'//ggg/ancestor::*',
	[
		{'type' => 'root'},
		{'nodename' => 'aaa', 'id' => 'a1'},
		{'nodename' => 'xxx', 'id' => 'x1'},
		{'nodename' => 'ddd', 'id' => 'd2'},
		{'nodename' => 'fff', 'id' => 'f1'},
	]
);

test_nodeset(
	'//ggg/descendant::*',
	[
		{'nodename' => 'jjj', 'id' => 'j1'},
		{'nodename' => 'qqq', 'id' => 'q1'},
		{'nodename' => 'jjj', 'id' => 'j2'},
	]
);

test_nodeset(
	'//ggg/following::*',
	[
		{'nodename' => 'hhh', 'id' => 'h2'},
		{'nodename' => 'ccc', 'id' => 'c2'},
		{'nodename' => 'ddd', 'id' => 'd3'},
	]
);

test_nodeset(
	'//ggg/preceding::*',
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'ccc', 'id' => 'c1'},
		{'nodename' => 'zzz', 'id' => 'z1'},
		{'nodename' => 'eee', 'id' => 'e1'},
		{'nodename' => 'hhh', 'id' => 'h1'},
	]
);

test_nodeset(
	'//ggg/self::*',
	[
		{'nodename' => 'ggg', 'id' => 'g1'},
	]
);

test_nodeset(
	'//ggg/ancestor::* | //ggg/descendant::* | //ggg/following::* | //ggg/preceding::* | //ggg/self::*',
	[
		{'type' => 'root'},
		{'nodename' => 'aaa', 'id' => 'a1'},
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'ccc', 'id' => 'c1'},
		{'nodename' => 'zzz', 'id' => 'z1'},
		{'nodename' => 'xxx', 'id' => 'x1'},
		{'nodename' => 'ddd', 'id' => 'd2'},
		{'nodename' => 'eee', 'id' => 'e1'},
		{'nodename' => 'fff', 'id' => 'f1'},
		{'nodename' => 'hhh', 'id' => 'h1'},
		{'nodename' => 'ggg', 'id' => 'g1'},
		{'nodename' => 'jjj', 'id' => 'j1'},
		{'nodename' => 'qqq', 'id' => 'q1'},
		{'nodename' => 'jjj', 'id' => 'j2'},
		{'nodename' => 'hhh', 'id' => 'h2'},
		{'nodename' => 'ccc', 'id' => 'c2'},
		{'nodename' => 'ddd', 'id' => 'd3'},
	]
);

