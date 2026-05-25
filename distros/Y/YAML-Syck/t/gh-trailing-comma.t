use strict;
use warnings;
use Test::More tests => 8;
use YAML::Syck;

# GitHub issue #195: trailing commas in flow collections are valid YAML
# (all spec versions: 1.0, 1.1, 1.2) but YAML-Syck rejected them.

# Flow sequences with trailing comma
is_deeply eval { Load("test: [a, b, c,]\n") }, { test => [qw(a b c)] },
    'flow sequence with trailing comma';

is_deeply eval { Load("test: [a,]\n") }, { test => ['a'] },
    'single-element flow sequence with trailing comma';

is_deeply Load("test: [a, b, c]\n"), { test => [qw(a b c)] },
    'flow sequence without trailing comma still works';

is_deeply Load("test: []\n"), { test => [] },
    'empty flow sequence still works';

# Flow mappings with trailing comma
is_deeply eval { Load("test: {a: 1, b: 2,}\n") }, { test => { a => 1, b => 2 } },
    'flow mapping with trailing comma';

is_deeply eval { Load("test: {a: 1,}\n") }, { test => { a => 1 } },
    'single-entry flow mapping with trailing comma';

is_deeply Load("test: {a: 1, b: 2}\n"), { test => { a => 1, b => 2 } },
    'flow mapping without trailing comma still works';

is_deeply Load("test: {}\n"), { test => {} },
    'empty flow mapping still works';
