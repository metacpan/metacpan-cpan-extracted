#!/usr/bin/perl
#
# Non-regression tests for the numeric helpers of oEdtk::Main.
#
# oEdtk::Main is loaded at runtime (quiet_require), so its (\$) prototypes are
# NOT applied at compile time here: scalar-reference arguments are passed
# explicitly.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use TestOEdtk qw(quiet_require);

quiet_require('oEdtk::Main');

# --- oe_round ---------------------------------------------------------------
is(oEdtk::Main::oe_round(1234.5678),     "1234.57", 'oe_round defaults to 2 decimals');
is(oEdtk::Main::oe_round(1234.5678, 0.1), "1234.6", 'oe_round honours a 0.1 multiple');
is(oEdtk::Main::oe_round(1234.5678, 1),  "1235",    'oe_round honours a unit multiple');

# --- oe_num_sign_x ----------------------------------------------------------
my $s = "213y";
is(oEdtk::Main::oe_num_sign_x(\$s), -2139, 'oe_num_sign_x decodes the y sign');
is($s, -2139, 'oe_num_sign_x mutates its argument');

$s = "0";
is(oEdtk::Main::oe_num_sign_x(\$s), 1, 'oe_num_sign_x returns 1 for a zero value');
is($s, 0, '... and normalises it to 0');

$s = "";
is(oEdtk::Main::oe_num_sign_x(\$s), 1, 'oe_num_sign_x returns 1 for an empty value');
is($s, 0, '... and normalises it to 0');

$s = "1234";
is(oEdtk::Main::oe_num_sign_x(\$s, 2), 12.34, 'oe_num_sign_x applies the decimal divisor');

{
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	$s = "12ab";   # two consecutive non-digits trigger the "not numeric" branch
	is(oEdtk::Main::oe_num_sign_x(\$s), -1, 'oe_num_sign_x returns -1 for a non-numeric value');
	like($w[0] // '', qr/not numeric/, '... and warns');
}

# --- oe_num2txt_us ----------------------------------------------------------
$s = "1 234,56-";
is(oEdtk::Main::oe_num2txt_us(\$s), "-1234.56", 'oe_num2txt_us converts US layout and sign');
is($s, "-1234.56", 'oe_num2txt_us mutates its argument');

$s = "1.234,56";
is(oEdtk::Main::oe_num2txt_us(\$s), "1234.56", 'oe_num2txt_us strips thousands separator');

$s = "";
is(oEdtk::Main::oe_num2txt_us(\$s), 0, 'oe_num2txt_us returns 0 for an empty value');

done_testing();
