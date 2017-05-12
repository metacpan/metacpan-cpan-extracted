use Test::More 'no_plan';
use_ok('WWW::Hotmail');

my $foo = new WWW::Hotmail;
isa_ok($foo, "WWW::Hotmail");

# Much as I'm prepared to do without giving away credentials,
# unfortunately. Trust me, it works.
