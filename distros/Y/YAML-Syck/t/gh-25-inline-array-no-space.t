use strict;
use warnings;
use Test::More tests => 6;

use YAML::Syck;

# GitHub #25 / RT #116654: Inline arrays with quoted strings and no space
# after comma should parse correctly, e.g. ['*:80','*:443']

# Exact case from the bug report: single-quoted strings with special chars
is_deeply(
    Load("---\nports: ['*:80','*:443']\n"),
    { ports => ['*:80', '*:443'] },
    'single-quoted strings with special chars, no space after comma'
);

# Double-quoted strings without space after comma
is_deeply(
    Load("---\nports: [\"*:80\",\"*:443\"]\n"),
    { ports => ['*:80', '*:443'] },
    'double-quoted strings with special chars, no space after comma'
);

# Mixed quoted and unquoted without spaces
is_deeply(
    Load("--- ['a',b,'c']\n"),
    ['a', 'b', 'c'],
    'mixed quoted and unquoted without spaces after commas'
);

# Quoted strings containing commas (should not split)
is_deeply(
    Load("--- ['a,b','c,d']\n"),
    ['a,b', 'c,d'],
    'quoted strings containing commas'
);

# Inline map with quoted values, no space after comma
is_deeply(
    Load("--- {a: '1',b: '2'}\n"),
    { a => '1', b => '2' },
    'inline map with quoted values, no space after comma'
);

# Three or more quoted elements without spaces
is_deeply(
    Load("--- ['x','y','z']\n"),
    ['x', 'y', 'z'],
    'three quoted elements without spaces after commas'
);
