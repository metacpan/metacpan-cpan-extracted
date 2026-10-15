#!/usr/bin/env perl
# json_file_to_ref() / ref_to_json_file(): JSON round-trip, plus the
# NaN/Infinity -> null rewrite that json_file_to_ref performs for
# Python/NumPy-emitted files.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Capture::Tiny 'capture';
use File::Temp qw(tempfile tempdir);
use File::Spec;
use Util::Con;

my $dir = tempdir( CLEANUP => 1 );

# --- round trip through both functions ---
# NB: no JSON booleans (\1) here -- those decode to JSON::PP::Boolean objects,
# not back to \1, so is_deeply would (correctly) report them as unequal.
my $data = { name => 'x', nums => [1, 2, 3], nested => { ok => 'yes' } };
my $out  = File::Spec->catfile($dir, 'rt.json');

my $returned;
capture { $returned = ref_to_json_file($data, $out) };   # prints "Wrote ..."
is( $returned, $out, 'ref_to_json_file returns the filename it wrote' );
ok( -s $out, 'ref_to_json_file created a non-empty file' );

my $back = json_file_to_ref($out);
is_deeply( $back, $data, 'data survives a write/read round trip' );

# --- NaN / Infinity handling ---
my $nan = File::Spec->catfile($dir, 'nan.json');
open my $nfh, '>', $nan or die $!;
print $nfh '{"a": NaN, "b": [1, Infinity, -Infinity], "c": "NaN in string"}';
close $nfh;

my $ref = json_file_to_ref($nan);
ok( !defined $ref->{a},    'bare NaN becomes undef' );
is( $ref->{b}[0], 1,       'real numbers next to Infinity are preserved' );
ok( !defined $ref->{b}[1], 'bare Infinity becomes undef' );
ok( !defined $ref->{b}[2], 'bare -Infinity becomes undef' );
is( "$ref->{c}", 'NaN in string',
	'the literal text "NaN" inside a string is NOT rewritten' );

# --- error handling ---
throws_ok { json_file_to_ref(File::Spec->catfile($dir, 'missing.json')) }
	qr/doesn't exist/, 'missing file is rejected';

my $empty = File::Spec->catfile($dir, 'empty.json');
open my $efh, '>', $empty or die $!; close $efh;
throws_ok { json_file_to_ref($empty) } qr/0 size/, 'zero-size file is rejected';

throws_ok { ref_to_json_file($data, [] ) }
	qr/isn't a scalar/, 'ref_to_json_file rejects a non-scalar filename';

done_testing;
