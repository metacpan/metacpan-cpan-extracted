use Test::More tests => 12;

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
	'//ddd/parent::*',
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'ccc', 'id' => 'c1'},
		{'nodename' => 'ccc', 'id' => 'c2'},
		{'nodename' => 'eee', 'id' => 'e2'},
	]
);

# this test doesn't appear on zvon any more...

test_nodeset(
	'/*/*/parent::*',
	[
		{'nodename' => 'aaa', 'id' => 'a1'},
	]
);
