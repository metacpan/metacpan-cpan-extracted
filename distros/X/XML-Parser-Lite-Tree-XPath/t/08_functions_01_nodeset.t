use Test::More tests => 61;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

#
# all functions are defined here:
# http://www.w3.org/TR/xpath#corelib
#

set_xml(q!
	<aaa>
		<bbb id="b1" />
		<bbb id="b2">
			<ddd id="d1" />
			<ddd id="d2" />
		</bbb>
		<bbb foo="bar">
			<ccc />
		</bbb>
	</aaa>
!);


#
# Function: number last()
# The last function returns a number equal to the context size from the expression evaluation context.
#

test_nodeset(
	'//bbb[last()]',
	[
		{'nodename' => 'bbb', 'foo' => 'bar'},
	]
);


#
# Function: number position()
# The position function returns a number equal to the context position from the expression evaluation context.
#

test_nodeset(
	'//bbb[position() = 1]',
	[
		{'nodename' => 'bbb', id => 'b1'},
	]
);


#
# Function: number count(node-set)
# The count function returns the number of nodes in the argument node-set.
#

test_nodeset(
	'//bbb[count(*) = 2]',
	[
		{'nodename' => 'bbb', id => 'b2'},
	]
);
test_number('count(//*)', 7);
test_number('count(//bbb)', 3);


#
# Function: node-set id(object)
# The id function selects elements by their unique ID
#

set_xml(q!
	<aaa>
		<bbb id="b1" />
		<bbb id="b2" />
		<bbb id="b3">b2</bbb>
		<ccc>b3</ccc>
	</aaa>
!);

test_nodeset(
	'id("b2")',
	[
		{'nodename' => 'bbb', id => 'b2'},
	]
);

test_nodeset(
	'id("b1 b2")',
	[
		{'nodename' => 'bbb', id => 'b1'},
		{'nodename' => 'bbb', id => 'b2'},
	]
);

test_nodeset(
	'id(//*)', # this test is odd - it grabs the text node as the name to check against
	[
		{'nodename' => 'bbb', id => 'b2'},
		{'nodename' => 'bbb', id => 'b3'},
	]
);

test_nodeset(
	'id(/aaa/ccc)',
	[
		{'nodename' => 'bbb', id => 'b3'},
	]
);


#
# Function: string local-name(node-set?)
# The local-name function returns the local part of the expanded-name of the node in the argument node-set that is first in document order.
#

set_xml(q!
	<aaa
		xmlns="urn:default"
		xmlns:foo="urn:foo"
	>
		<bbb id="b1" />
		<bbb id="b2" />
		<foo:bbb id="b3" />
	</aaa>
!);

test_nodeset(
	'//*[local-name() = "bbb"]',
	[
		{'nodename' => 'bbb', id => 'b1'},
		{'nodename' => 'bbb', id => 'b2'},
		{'nodename' => 'foo:bbb', id => 'b3'},
	]
);

test_string('local-name()', ''); # defaults to context, which is root (no local name)
test_string('local-name(/aaa)', 'aaa');
test_string('local-name(//*)', 'aaa');
test_string('local-name(/aaa/*[1])', 'bbb');
test_string('local-name(/aaa/*[3])', 'bbb');


#
# Function: string namespace-uri(node-set?)
# The namespace-uri function returns the namespace URI of the expanded-name of the node in the argument node-set that is first in document order.
#

test_nodeset(
	'//*[namespace-uri() = "urn:foo"]',
	[
		{'nodename' => 'foo:bbb', id => 'b3'},
	]
);

test_string('namespace-uri(/aaa)', 'urn:default');
test_string('namespace-uri(//bbb)', 'urn:default');
test_string('namespace-uri(/aaa/*[3])', 'urn:foo');


#
# Function: string name(node-set?)
# The name function returns a string containing a QName representing the expanded-name of the node in the argument node-set that is first in document order.
#

test_string('name()', '');
test_string('name(/aaa)', 'aaa');
test_string('name(/aaa/*[3])', 'foo:bbb');
