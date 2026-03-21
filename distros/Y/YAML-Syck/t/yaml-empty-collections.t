use strict;
use warnings;
use Test::More tests => 10;

use YAML::Syck;

# GitHub #36: Empty arrays/hashes should not emit extra newlines

# Root-level empty array
is( Dump([]), "--- []\n", 'root empty array has no extra newline' );

# Root-level empty hash
is( Dump({}), "--- {}\n", 'root empty hash has no extra newline' );

# Empty array in map - no blank line between entries
my $map_yaml = Dump({ a => [], b => 'val' });
unlike( $map_yaml, qr/\[\]\n\n/, 'empty array in map has no extra newline' );
like( $map_yaml, qr/a: \[\]\n[a-z]/, 'next key follows immediately after empty array' );

# Empty hash in map
my $map_yaml2 = Dump({ a => {}, b => 'val' });
unlike( $map_yaml2, qr/\{\}\n\n/, 'empty hash in map has no extra newline' );
like( $map_yaml2, qr/a: \{\}\n[a-z]/, 'next key follows immediately after empty hash' );

# Empty containers in sequence
my $seq_yaml = Dump([ [], {}, 'after' ]);
unlike( $seq_yaml, qr/\[\]\n\n/, 'empty array in seq has no extra newline' );
unlike( $seq_yaml, qr/\{\}\n\n/, 'empty hash in seq has no extra newline' );

# Roundtrip preserves empty containers
my $data = { x => [], y => {}, z => [1] };
my $back = Load(Dump($data));
is_deeply( $back->{x}, [], 'empty array roundtrips correctly' );
is_deeply( $back->{y}, {}, 'empty hash roundtrips correctly' );
