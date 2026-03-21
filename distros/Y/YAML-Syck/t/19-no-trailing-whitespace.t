use strict;
use warnings;
use Test::More tests => 4;

use YAML::Syck;

# RT #46983 / GitHub #38 - Trailing whitespace at first EOL when dumping a hash
# When dumping a hash or array, YAML::Syck should not output trailing
# whitespace on the "---" line.

my $hash_yaml = Dump({ a => 1 });
unlike( $hash_yaml, qr/ \n/, 'no trailing whitespace when dumping a hash' );
like( $hash_yaml, qr/^---\n/, 'hash dump starts with "---" followed by newline, no space' );

my $array_yaml = Dump([ 1, 2 ]);
unlike( $array_yaml, qr/ \n/, 'no trailing whitespace when dumping an array' );

# Scalars should still have space separator: "--- value\n"
is( Dump("hello"), "--- hello\n", 'scalar dump still has space separator' );
