#!perl
use strict;
use warnings;
use Test::More tests => 3;


BEGIN { use_ok('Test::InDomain', -constructors => {-prefix => "dom_"}); }

my $dom = dom_Int(-min => 3);
in_domain     5, $dom, "foo";

$dom = dom_List(dom_Int, dom_List, dom_String);
in_domain [1, [], 123], $dom, "list";


