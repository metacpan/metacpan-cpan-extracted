use Test::More tests => 10;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa>
		<bbb />
		<ccc />
	</aaa>
!);

test_nodeset(
	'/aaa',
	[
		{'nodename' => 'aaa'},
	]
);

test_nodeset(
	'/child::aaa',
	[
		{'nodename' => 'aaa'},
	]
);

test_nodeset(
	'/aaa/bbb',
	[
		{'nodename' => 'bbb'},
	]
);

test_nodeset(
	'/child::aaa/child::bbb',
	[
		{'nodename' => 'bbb'},
	]
);

test_nodeset(
	'/child::aaa/bbb',
	[
		{'nodename' => 'bbb'},
	]
);


