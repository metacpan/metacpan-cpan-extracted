use Test::More tests => 2;
BEGIN { use_ok('Text::Toalpha') };
is(Text::Toalpha::fromalpha(Text::Toalpha::toalpha("foo")), "foo", "round-trip");
