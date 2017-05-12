use Test::More tests => 12;
use Text::CommonParts qw(common_parts);

my @out;
my @in;

@in = ("foo bar");
ok(@out = common_parts(@in));
is_deeply(["foo bar"], [sort @out]);

@in = ("foo bar", "foo quirka");
ok(@out = common_parts(@in));
is_deeply(["foo"],[sort @out]);

@in = ("foo bar", "foo quirka fleeg", "foo quirka quux");
ok(@out = common_parts(@in));
is_deeply(["foo bar", "foo quirka"],[sort @out]);

@in = ("foo bar", "foo quirka fleeg", "foo quirka quux", "something other");
ok(@out = common_parts(@in));
is_deeply(["foo bar", "foo quirka", "something other"],[sort @out]);

@in = ("foo bar", "foo do", "foo quirka fleeg", "foo quirka quux");
ok(@out = common_parts(@in));
is_deeply(["foo", "foo quirka"],[sort @out]);

@in = ("foo bar", "foo do", "foo quirka fleeg", "foo quirka quux", "something other");
ok(@out = common_parts(@in));
is_deeply(["foo", "foo quirka", "something other"],[sort @out]);


