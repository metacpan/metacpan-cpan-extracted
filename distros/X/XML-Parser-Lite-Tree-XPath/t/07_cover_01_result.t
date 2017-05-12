use Test::More tests => 69;

use strict;
use lib 'lib';
use XML::Parser::Lite::Tree::XPath::Result;


#
# junk/error type conversions
#

compare(XML::Parser::Lite::Tree::XPath::Result->new('junk')->get_boolean, 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('junk')->get_number, 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('junk')->get_string, 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('junk')->get_nodeset, 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('junk')->get_node, 'Error');

compare(XML::Parser::Lite::Tree::XPath::Result->new('Error')->get_boolean, 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('Error')->get_number, 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('Error')->get_string, 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('Error')->get_nodeset, 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('Error')->get_node, 'Error');

compare(XML::Parser::Lite::Tree::XPath::Result->new('junk')->get_type('boolean'), 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('junk')->get_type('number'), 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('junk')->get_type('string'), 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('junk')->get_type('nodeset'), 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('junk')->get_type('node'), 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('junk')->get_type('junk'), 'Error');
compare(XML::Parser::Lite::Tree::XPath::Result->new('junk')->get_type('Error'), 'Error');



#
# number -> (number, boolean, string, nodeset, node)
#

compare(XML::Parser::Lite::Tree::XPath::Result->new('number', 1)->get_number, 'number', 1);
compare(XML::Parser::Lite::Tree::XPath::Result->new('number', 1.1)->get_number, 'number', 1.1);
compare(XML::Parser::Lite::Tree::XPath::Result->new('number', 'NaN')->get_number, 'number', 'NaN');

compare(XML::Parser::Lite::Tree::XPath::Result->new('number', 1)->get_boolean, 'boolean', 1);
compare(XML::Parser::Lite::Tree::XPath::Result->new('number', 0)->get_boolean, 'boolean', 0);
compare(XML::Parser::Lite::Tree::XPath::Result->new('number', 'NaN')->get_boolean, 'boolean', 0);

compare(XML::Parser::Lite::Tree::XPath::Result->new('number', 1)->get_string, 'string', '1');
compare(XML::Parser::Lite::Tree::XPath::Result->new('number', 1.1)->get_string, 'string', '1.1');
compare(XML::Parser::Lite::Tree::XPath::Result->new('number', 'NaN')->get_string, 'string', 'NaN');

compare(XML::Parser::Lite::Tree::XPath::Result->new('number', 1)->get_nodeset, 'Error');

compare(XML::Parser::Lite::Tree::XPath::Result->new('number', 1)->get_node, 'Error');


#
# boolean -> (number, boolean, string, nodeset, node)
#

compare(XML::Parser::Lite::Tree::XPath::Result->new('boolean', 1)->get_number, 'number', 1);
compare(XML::Parser::Lite::Tree::XPath::Result->new('boolean', 0)->get_number, 'number', 0);

compare(XML::Parser::Lite::Tree::XPath::Result->new('boolean', 1)->get_boolean, 'boolean', 1);
compare(XML::Parser::Lite::Tree::XPath::Result->new('boolean', 0)->get_boolean, 'boolean', 0);

compare(XML::Parser::Lite::Tree::XPath::Result->new('boolean', 1)->get_string, 'string', 'true');
compare(XML::Parser::Lite::Tree::XPath::Result->new('boolean', 0)->get_string, 'string', 'false');

compare(XML::Parser::Lite::Tree::XPath::Result->new('boolean', 0)->get_nodeset, 'Error');

compare(XML::Parser::Lite::Tree::XPath::Result->new('boolean', 0)->get_node, 'Error');


#
# string -> (number, boolean, string, nodeset, node)
#

compare(XML::Parser::Lite::Tree::XPath::Result->new('string', 'hello world')->get_number, 'number', 'NaN');
compare(XML::Parser::Lite::Tree::XPath::Result->new('string', '1')->get_number, 'number', 1);
compare(XML::Parser::Lite::Tree::XPath::Result->new('string', '1.1')->get_number, 'number', 1.1);
compare(XML::Parser::Lite::Tree::XPath::Result->new('string', ' 1.1 ')->get_number, 'number', 1.1);
compare(XML::Parser::Lite::Tree::XPath::Result->new('string', '-1')->get_number, 'number', -1);

compare(XML::Parser::Lite::Tree::XPath::Result->new('string', 'hello world')->get_boolean, 'boolean', 1);
compare(XML::Parser::Lite::Tree::XPath::Result->new('string', '')->get_boolean, 'boolean', 0);

compare(XML::Parser::Lite::Tree::XPath::Result->new('string', 'hello world')->get_string, 'string', 'hello world');

compare(XML::Parser::Lite::Tree::XPath::Result->new('string', 'hello world')->get_nodeset, 'Error');

compare(XML::Parser::Lite::Tree::XPath::Result->new('string', 'hello world')->get_node, 'Error');


#
# nodeset -> (number, boolean, string, nodeset, node)
#


#
# node -> (number, boolean, string, nodeset, node)
#




##################################################################################################

sub compare {
	my ($a, $t, $v) = @_;

	ok($a->{type} eq $t);
	print "$a->{type} eq $t\n" unless $a->{type} eq $t;

	if ($a->{type} eq 'string'){
		ok($a->{value} eq $v);
		print "$a->{value} eq $v\n" unless $a->{value} eq $v;
	}

	if ($a->{type} eq 'number'){
		ok($a->{value} eq $v);
		print "$a->{value} eq $v\n" unless $a->{value} eq $v;
	}

	if ($a->{type} eq 'boolean'){
		my $ok = ($a->{value} && $v) || (!$a->{value} && !$v);
		ok($ok);
		print "$a->{value} eq $v\n" unless $ok;
	}
}
