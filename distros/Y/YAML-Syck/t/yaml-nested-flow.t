use strict;
use warnings;
use Test::More tests => 8;

use YAML::Syck;

# RT #62077 / GitHub #40: Flow sequences with commas not followed by spaces
# should still parse correctly, especially nested flow sequences like [[a,b],[c,d]]

# Simple flow sequence without spaces after commas
is_deeply(
    Load("--- [a,b,c]\n"),
    ['a', 'b', 'c'],
    'flow sequence without spaces after commas'
);

# Nested flow sequences (lists of lists)
is_deeply(
    Load("--- [[x,ch],[ss,o]]\n"),
    [['x', 'ch'], ['ss', 'o']],
    'nested flow sequences without spaces'
);

# Nested flow sequences with spaces
is_deeply(
    Load("--- [[x, ch], [ss, o]]\n"),
    [['x', 'ch'], ['ss', 'o']],
    'nested flow sequences with spaces'
);

# Mixed spacing
is_deeply(
    Load("--- [[x,ch], [ss, o]]\n"),
    [['x', 'ch'], ['ss', 'o']],
    'nested flow sequences with mixed spacing'
);

# Flow sequence as map value without spaces
is_deeply(
    Load("key: [a,b,c]\n"),
    { key => ['a', 'b', 'c'] },
    'flow sequence as map value without spaces after commas'
);

# Nested flow sequences as map value (the original bug report)
is_deeply(
    Load("SNDCLASSES: [[x,ch],[ss,o]]\n"),
    { SNDCLASSES => [['x', 'ch'], ['ss', 'o']] },
    'nested flow sequences as map value'
);

# Full example from the bug report
my $yaml = <<'YAML';
META:
 LANG: "Portugu\xEAs"
 VARIANT: Europeu
 IDS: [port, pt, pt_PT]
 SNDCLASSES: [[x,ch],[ss,o]]
YAML

my $data = Load($yaml);
is_deeply(
    $data->{META}{IDS},
    ['port', 'pt', 'pt_PT'],
    'IDS parsed correctly from full example'
);
is_deeply(
    $data->{META}{SNDCLASSES},
    [['x', 'ch'], ['ss', 'o']],
    'SNDCLASSES parsed correctly from full example'
);
