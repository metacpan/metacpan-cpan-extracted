use Test::More tests => 2;
BEGIN { use_ok('Text::Toalpha') };
is(Text::Toalpha::toalpha("foo"), "dyeheh", "expected input produces expected output");
