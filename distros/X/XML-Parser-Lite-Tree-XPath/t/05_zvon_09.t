use Test::More tests => 10;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa>
		<q />
		<ssss />
		<bb />
		<ccc />
		<dddddddd />
		<eeee />
	</aaa>
!);

test_nodeset(
	q!//*[string-length(name()) = 3]!,
	[
		{'nodename' => 'aaa'},
		{'nodename' => 'ccc'},
	]
);

test_nodeset(
	q!//*[string-length(name()) < 3]!,
	[
		{'nodename' => 'q'},
		{'nodename' => 'bb'},
	]
);

test_nodeset(
	q!//*[string-length(name()) > 3]!,
	[
		{'nodename' => 'ssss'},
		{'nodename' => 'dddddddd'},
		{'nodename' => 'eeee'},
	]
);
