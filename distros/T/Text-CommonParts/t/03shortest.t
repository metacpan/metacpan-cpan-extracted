use Test::More tests => 12;
use Text::CommonParts qw(shortest_common_parts);

my @out;
my @in;

@in = ("foo bar");
ok(@out = shortest_common_parts(@in));
is_deeply(["foo bar"], [sort @out]);

@in = ("foo bar", "foo quirka");
ok(@out = shortest_common_parts(@in));
is_deeply(["foo"],[sort @out]);

@in = ("foo bar", "foo quirka fleeg", "foo quirka quux");
ok(@out = shortest_common_parts(@in));
is_deeply(["foo"],[sort @out]);

@in = ("foo bar", "foo quirka fleeg", "foo quirka quux", "something other");
ok(@out = shortest_common_parts(@in));
is_deeply(["foo", "something other"],[sort @out]);

@in = ("foo bar", "foo do", "foo quirka fleeg", "foo quirka quux");
ok(@out = shortest_common_parts(@in));
is_deeply(["foo"],[sort @out]);

@in = ("foo bar", "foo do", "foo quirka fleeg", "foo quirka quux", "something other");
ok(@out = shortest_common_parts(@in));
is_deeply(["foo", "something other"],[sort @out]);


