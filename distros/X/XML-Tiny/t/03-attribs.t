use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";
print "1..8\n";

$^W = 1;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

is_deeply(
    parsefile(q{_TINY_XML_STRING_<x a="A" b="B C"/>}),
    [{ 'name' => 'x', 'content' => [], 'type' => 'e', attrib => { a => 'A', b => 'B C' }}],
    "Double-quoted attributes parsed correctly"
);

is_deeply(
    parsefile(q{_TINY_XML_STRING_<x a='A' b='B C'/>}),
    [{ 'name' => 'x', 'content' => [], 'type' => 'e', attrib => { a => 'A', b => 'B C' }}],
    "Single-quoted attributes parsed correctly"
);

is_deeply(
    parsefile(q{_TINY_XML_STRING_<x single = '"' double = "'"/>}),
    [{ 'name' => 'x', 'content' => [], 'type' => 'e', attrib => { single => '"', double => "'" }}],
    "Quoted quotes in attributes parsed correctly"
);

# > sign in something that looks like an attrib
is_deeply(
    parsefile(q{_TINY_XML_STRING_<x>foo = ">"</x>}),
    [{ 'name' => 'x', 'content' => [{ 'content' => 'foo = ">"', 'type' => 't'}], 'type' => 'e', attrib => {}}],
    "> signs in data that looks like attribs but isn't work OK"
);

# > sign in attrib
is_deeply(
    parsefile(q{_TINY_XML_STRING_<x a='foo>'><y b=">>>" /></x>}),
    [{ 'name' => 'x', 'content' => [{ 'name' => 'y', 'content' => [], 'type' => 'e', attrib => { b => '>>>' }}], 'type' => 'e', attrib => { a => 'foo>' }}],
    "Quoted > signs work"
);

eval { parsefile(q{_TINY_XML_STRING_<x a='<'/>}) };
ok($@, "Illegal < in attributes is fatal");
eval { parsefile(q{_TINY_XML_STRING_<x a="""/>}) };
ok($@, "Badly nested \" in attributes is fatal");
eval { parsefile(q{_TINY_XML_STRING_<x a='''/>}) };
ok($@, "Badly nested  ' in attributes is fatal");
