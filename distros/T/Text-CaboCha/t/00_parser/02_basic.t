use strict;
use Test::More;
BEGIN { use_ok("Text::CaboCha") }

my $cabocha = Text::CaboCha->new(ne => 1);
ok($cabocha);

is(Text::CaboCha::version(), Text::CaboCha::CABOCHA_VERSION, "get cabocha version");

done_testing;