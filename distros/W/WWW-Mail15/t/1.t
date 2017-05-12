use Test::More 'no_plan';
use_ok('WWW::Mail15');

my $foo = new WWW::Mail15;
isa_ok($foo, "WWW::Mail15");

# Much as I'm prepared to do without giving away credentials,
# unfortunately. Trust me, it works.
