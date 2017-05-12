use Test::More tests => 28;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa>
		<bcc>
			<bbb id="b1" />
			<bbb id="b2" />
			<bbb id="b3" />
		</bcc>
		<ddb>
			<bbb id="b4" />
			<bbb id="b5" />
		</ddb>
		<bec>
			<ccc />
			<dbd />
		</bec>
	</aaa>
!);

test_nodeset(
	q!//*[name()='bbb']!,
	[
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'bbb', 'id' => 'b2'},
		{'nodename' => 'bbb', 'id' => 'b3'},
		{'nodename' => 'bbb', 'id' => 'b4'},
		{'nodename' => 'bbb', 'id' => 'b5'},
	]
);

test_nodeset(
	q!//*[starts-with(name(),'b')]!,
	[
		{'nodename' => 'bcc'},
		{'nodename' => 'bbb', 'id' => 'b1'},
		{'nodename' => 'bbb', 'id' => 'b2'},
		{'nodename' => 'bbb', 'id' => 'b3'},
		{'nodename' => 'bbb', 'id' => 'b4'},
		{'nodename' => 'bbb', 'id' => 'b5'},
		{'nodename' => 'bec'},
	]
);

test_nodeset(
	q!//*[contains(name(),'c')]!,
	[
		{'nodename' => 'bcc'},
		{'nodename' => 'bec'},
		{'nodename' => 'ccc'},
	]
);
