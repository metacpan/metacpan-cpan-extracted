use Test::More tests => 1;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;

#
# all functions are defined here:
# http://www.w3.org/TR/xpath#corelib
#

set_xml(q!
	<aaa>
		<bbb/>
		<bbb>woo</bbb>
		<bbb>yay</bbb>
	</aaa>
!);

ok(1);


#
# Function: number number(object?)
# The number function converts its argument to a number as follows: ...
#

#
# Function: number sum(node-set)
# The sum function returns the sum, for each node in the argument node-set, of the
# result of converting the string-values of the node to a number.
#

#
# Function: number floor(number)
# The floor function returns the largest (closest to positive infinity) number that
# is not greater than the argument and that is an integer.
#

#
# Function: number ceiling(number)
# The ceiling function returns the smallest (closest to negative infinity) number
# that is not less than the argument and that is an integer.
#

#
# Function: number round(number)
# The round function returns the number that is closest to the argument and that is
# an integer. 
#
