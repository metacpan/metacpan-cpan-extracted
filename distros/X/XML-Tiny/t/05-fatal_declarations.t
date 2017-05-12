use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";
print "1..2\n";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

eval { parsefile(q{_TINY_XML_STRING_<!ENTITY...><x></x>}, fatal_declarations => 1) };
ok($@, "fatal_declarations really is fatal ...");

ok(parsefile(q{_TINY_XML_STRING_<!ENTITY...><x></x>}),
    "... but we can live without it");
