########## STANDARD Does it compile TEST - DO NOT EDIT ##################
use Test::More tests => 2;

BEGIN {
  use_ok('Test::XML::Easy');
}

ok(defined &is_xml,"exported function okay");
