use warnings;
use strict;

use Test::More tests => 1 + 3*4;

use_ok "XML::Easy::SimpleSchemaUtil";

foreach(
	[qw(xs_charcanon xml_s_canonise_chars)],
	[qw(xc_charcanon xml_c_canonise_chars)],
	[qw(xc_subelems xml_c_subelements)],
	[qw(xc_chars xml_c_chardata)],
) {
	my($alias, $orig) = @$_;
	no strict "refs";
	ok defined(&{"XML::Easy::SimpleSchemaUtil::$alias"});
	ok \&{"XML::Easy::SimpleSchemaUtil::$alias"} ==
		\&{"XML::Easy::SimpleSchemaUtil::$orig"};
	use_ok "XML::Easy::SimpleSchemaUtil", $alias;
}

1;
