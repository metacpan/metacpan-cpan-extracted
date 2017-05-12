use Test::More tests => 2;

my $pkg = 're::engine::PCRE2';
use_ok $pkg;
isa_ok(bless([] => $pkg), 'Regexp');
