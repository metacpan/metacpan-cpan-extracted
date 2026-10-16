#!/usr/bin/env perl
# format_commas: thousands separators + a formatted fractional part.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Util::Con;

# Default format is '.%02d' (two-decimal-ish fractional suffix).
is( format_commas(1234567.89), '1,234,567.89', 'seven-digit number with cents' );
is( format_commas(1000),       '1,000.00',     'exact thousand' );
is( format_commas(0),          '0.00',         'zero' );
is( format_commas(12.5),       '12.50',        'sub-thousand with half' );
is( format_commas(999),        '999.00',       'no grouping needed' );

# Integer mode: '%.0u' collapses the fractional suffix to empty.
is( format_commas(1234, '%.0u'), '1,234',   'integer format, no decimals' );
is( format_commas(1_000_000, '%.0u'), '1,000,000', 'million as integer' );

# The .005 fudge factor rounds the cents.
is( format_commas(1234.005), '1,234.01', 'half-cent rounds up' );

# --- Carry out of the fractional part rolls into the integer part. ---
# --- This used to emit a malformed ".100" suffix (999,999.100).     ---
is( format_commas(999999.999), '1,000,000.00', 'carry rolls into the integer part' );
is( format_commas(0.999),      '1.00',         'carry from a bare fraction' );
is( format_commas(1.999),      '2.00',         'carry with no grouping' );
is( format_commas(99.999),     '100.00',       'carry that widens the integer part' );
is( format_commas(0.995),      '1.00',         'exactly .995 rounds up and carries' );
is( format_commas(999999.999, '%.0u'), '1,000,000',
	'carry also works in integer format' );

# --- '%.0u' rounds a fraction to a whole number. ---
# --- It used to splice the hundredths on: 1234.56 came out "1,23456". ---
is( format_commas(1234.56, '%.0u'), '1,235',     'integer format rounds up' );
is( format_commas(1234.49, '%.0u'), '1,234',     'integer format rounds down' );
is( format_commas(1234.5,  '%.0u'), '1,235',     'integer format rounds half up' );
is( format_commas(0.4,     '%.0u'), '0',         'a fraction below one half is 0, not "040"' );
is( format_commas(999.5,   '%.0u'), '1,000',     'rounding that widens the integer part' );
is( format_commas(-1234.5, '%.0u'), '-1,235',    'negative fraction in integer format' );
is( format_commas(-0.4,    '%.0u'), '0',         'rounds to zero in integer format, so no sign' );

# --- Negative numbers: the sign is split off and the magnitude formatted. ---
# --- These used to emit "-1,234.-49" and lose the sign entirely on -0.5.  ---
is( format_commas(-1234.5),     '-1,234.50',     'negative with a fraction' );
is( format_commas(-0.5),        '-0.50',         'negative below 1 keeps its sign' );
is( format_commas(-1000000.99), '-1,000,000.99', 'negative with grouping' );
is( format_commas(-1234, '%.0u'), '-1,234',      'negative integer format' );
# A value that rounds away to zero is not reported as "-0.00".
is( format_commas(-0.001), '0.00', 'rounds to zero, so no sign' );

# --- Large magnitudes must not fall into scientific notation. ---
# --- int(1e20) stringifies as "1e+20", which grouping shredded to "1e,+20". ---
is( format_commas(1e20), '100,000,000,000,000,000,000.00', '1e20 groups as digits' );
is( format_commas(1e15), '1,000,000,000,000,000.00',       '1e15 groups as digits' );

done_testing;
