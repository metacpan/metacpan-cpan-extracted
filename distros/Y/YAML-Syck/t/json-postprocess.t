#!/usr/bin/perl -w

use strict;
use Test::More tests => 11;
use JSON::Syck;

# Test that JSON::Syck::Dump correctly postprocesses the C-level emitter
# output: strips spaces after ':' and ',' outside strings, removes
# trailing newline, and preserves special characters inside strings.

# Basic compact output (no spaces after : and ,)
{
    my $json = JSON::Syck::Dump({ a => 1, b => 2 });
    unlike( $json, qr/:\s/, "no space after colon in output" );
    unlike( $json, qr/,\s/, "no space after comma in output" );
    unlike( $json, qr/\n/,  "no trailing newline" );
}

# Colon and comma inside string values are preserved
{
    my $json = JSON::Syck::Dump({ key => "a: b, c" });
    is( $json, '{"key":"a: b, c"}', "colon and comma preserved inside strings" );
}

# Escaped quotes inside strings don't break string tracking
{
    my $json = JSON::Syck::Dump({ key => 'a"b' });
    is( $json, '{"key":"a\\"b"}', "escaped quotes handled correctly" );
}

# Backslashes inside strings
{
    my $json = JSON::Syck::Dump({ key => 'a\\b' });
    is( $json, '{"key":"a\\\\b"}', "backslashes inside strings preserved" );
}

# Nested structures
{
    my $json = JSON::Syck::Dump({ a => { b => [1, 2] } });
    unlike( $json, qr/:\s/, "nested structure: no space after colon" );
    unlike( $json, qr/,\s/, "nested structure: no space after comma" );
}

# Empty object/array
{
    my $json = JSON::Syck::Dump({});
    is( $json, '{}', "empty hash produces {}" );
}
{
    my $json = JSON::Syck::Dump([]);
    is( $json, '[]', "empty array produces []" );
}

# String with only special chars
{
    my $json = JSON::Syck::Dump({ k => ":,:" });
    is( $json, '{"k":":,:"}', "string of only colons and commas" );
}
