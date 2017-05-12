use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";
print "1..7\n";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

is_deeply(
    parsefile(q{_TINY_XML_STRING_<x>&&rubbish;&amp;&lt;&gt;&quot;&apos;</x>}),
    [{name => 'x', attrib => {}, type => 'e', content => [{type => 't', content => '&&rubbish;&<>"\''}]}],
    "All five entities are normally parsed OK"
);
is_deeply(
    parsefile(q{_TINY_XML_STRING_<x>&#65;</x>}),
    [{name => 'x', attrib => {}, type => 'e', content => [{type => 't', content => 'A'}]}],
    "base ten numeric char entities are normally parsed OK"
);
is_deeply(
    parsefile(q{_TINY_XML_STRING_<x>&#x41;</x>}),
    [{name => 'x', attrib => {}, type => 'e', content => [{type => 't', content => 'A'}]}],
    "base 16 numeric char entities are normally parsed OK"
);
is_deeply(
    parsefile(q{_TINY_XML_STRING_<x>&#xAa;</x>}),
    parsefile(q{_TINY_XML_STRING_<x>&#170;</x>}),
    "non-ASCII works, and hex entities aren't case-sensitive"
);

is_deeply(
    parsefile(q{_TINY_XML_STRING_<x>&&rubbish;&amp;&lt;&gt;&quot;&apos;</x>}, no_entity_parsing => 1),
    [{name => 'x', attrib => {}, type => 'e', content => [{type => 't', content => '&&rubbish;&amp;&lt;&gt;&quot;&apos;'}]}],
    "no_entity_parsing works"
);

eval { parsefile(q{_TINY_XML_STRING_<x>&</x>}, strict_entity_parsing => 1) };
ok($@, 'strict entity parsing hates naked ampersands');
eval { parsefile(q{_TINY_XML_STRING_<x>&rubbish;</x>}, strict_entity_parsing => 1) };
ok($@, 'strict entity parsing hates unknown entities');
