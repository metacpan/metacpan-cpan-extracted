use Test::More tests => 2;

my $pkg = 're::engine::Lua';
use_ok $pkg;
isa_ok(bless([] => $pkg), 'Regexp');
diag($re::engine::Lua::VERSION);
