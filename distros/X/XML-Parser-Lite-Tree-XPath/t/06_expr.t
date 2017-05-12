use Test::More tests => 31;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

use Data::Dumper;

set_xml(q!
	<aaa id="a1">
		<bbb id="b1" />
		<ccc id="c1" />
		<bbb id="b2" />
		<ddd>
			<bbb id="b3" />
		</ddd>
		<ccc id="c2" />
	</aaa>
!);

# super simple
test_number('1', 1);
test_number('-3', -3);

# ops
test_number('1+1', 2);
test_number('2-1', 1);
test_number('2*2', 4);
test_number('4 div 2', 2);

# spacing
test_number('1 +1', 2);
test_number('1+ 1', 2);
test_number('1 + 1', 2);

# mod
test_number('5 mod 2', 1);
test_number('5 mod -2', 1);
test_number('-5 mod 2', -1);
test_number('-5 mod -2', -1);

test_tree('-1',	  '[UnaryExpr:-[Number:1]]');
test_tree('2-1',  '[AdditiveExpr:-[Number:2][Number:1]]');
test_tree('2 -1', '[AdditiveExpr:-[Number:2][Number:1]]');
test_tree('2- 1', '[AdditiveExpr:-[Number:2][Number:1]]');
test_tree('2--1', '[AdditiveExpr:-[Number:2][UnaryExpr:-[Number:1]]]');

