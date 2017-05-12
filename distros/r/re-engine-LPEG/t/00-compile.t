use Test::More tests => 2;

my $pkg = 're::engine::LPEG';
use_ok $pkg;
isa_ok(bless([] => $pkg), 'Regexp');
