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
# Function: boolean boolean(object)
# The boolean function converts its argument to a boolean as follows: ...
#

#
# Function: boolean not(boolean)
# The not function returns true if its argument is false, and false otherwise.
#

#
# Function: boolean true()
# The true function returns true.
#

#
# Function: boolean false()
# The false function returns false.
#

#
# Function: boolean lang(string)
# The lang function returns true or false depending on whether the language of the 
# context node as specified by xml:lang attributes is the same as or is a sublanguage
# of the language specified by the argument string.
#


