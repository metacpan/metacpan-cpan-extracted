use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";
print "1..5\n";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

eval { parsefile('t/two-docs.xml'); };
ok($@ eq "Junk after end of document\n", "Fail if there's trailing XML crap");

eval { parsefile('t/doc-and-a-bit.xml'); };
ok($@ eq "Junk after end of document\n", "Fail if there's trailing text crap");

eval { parsefile('t/text-only.xml'); };
ok($@ eq "No elements\n", "Fail if there's text but no XML");

eval { parsefile('t/self-closing-optional-trailing-space.xml'); };
ok(!$@, "Don't fail on self-closing tags with no space before />");

is_deeply(
    parsefile('_TINY_XML_STRING_<a/>'),
    [{
        'attrib' => {},
        'name' => 'a',
        'content' => [],
        'type' => 'e'
    }],
    "No trailing slash on 'name' of self-closing tags"
);

