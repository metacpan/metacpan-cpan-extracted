use warnings;
use strict;

use Test::More tests => 18;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

my @funcs = qw(
	xml10_read_content xml10_read_element
	xml10_read_document xml10_read_extparsedent
	xml10_write_content xml10_write_element
	xml10_write_document xml10_write_extparsedent
);

use_ok "XML::Easy";
ok defined(&{"XML::Easy::$_"}) foreach @funcs;
ok \&{"XML::Easy::$_"} == \&{"XML::Easy::Text::$_"} foreach @funcs;
use_ok "XML::Easy", @funcs;

1;
