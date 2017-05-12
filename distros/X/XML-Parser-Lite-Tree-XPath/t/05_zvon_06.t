use Test::More tests => 11;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa>
		<bbb id="b1" />
		<bbb id="b2" name=" bbb " />
		<bbb id="b3" name="bbb" />
	</aaa>
!);

test_nodeset(
	q!//bbb[@id='b1']!,
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
	]
);

test_nodeset(
	q!//bbb[@name='bbb']!,
	[
		{'nodename' => 'bbb', 'id' => 'b3'},
	]
);

test_nodeset(
	q!//bbb[normalize-space(@name)='bbb']!,
	[
		{'nodename' => 'bbb', 'id' => 'b2'},
		{'nodename' => 'bbb', 'id' => 'b3'},
	]
);
