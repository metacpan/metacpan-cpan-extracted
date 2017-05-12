use Test::More tests => 2;
BEGIN { use_ok('Text::Toalpha') };
is(Text::Toalpha::fromalpha("dyeheh"), "foo", "converting expected output back to input");
