#!/usr/bin/perl
#
# Non-regression tests for the date helpers of oEdtk::Main.
#
# oEdtk::Main is loaded at runtime (quiet_require), so its (\$) prototypes are
# NOT applied at compile time here: scalar-reference arguments are passed
# explicitly (e.g. oe_to_date(\$s)).
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use TestOEdtk qw(quiet_require);

quiet_require('oEdtk::Main');

# --- oe_to_date : YYYYMMDD -> DD/MM/YYYY -------------------------------------
my $s = "20260709";
is(oEdtk::Main::oe_to_date(\$s), "09/07/2026", 'oe_to_date formats YYYYMMDD');
is($s, "09/07/2026", 'oe_to_date mutates its argument');
$s = "20260709XYZ";
is(oEdtk::Main::oe_to_date(\$s), "09/07/2026", 'oe_to_date ignores trailing characters');

# --- oe_fmt_date : normalise DD/MM/YYYY --------------------------------------
is(oEdtk::Main::oe_fmt_date("9/7/2026"),     "09/07/2026", 'oe_fmt_date zero-pads day/month');
is(oEdtk::Main::oe_fmt_date(" 1/2/2026 "),  "01/02/2026", 'oe_fmt_date tolerates surrounding spaces');
is(oEdtk::Main::oe_fmt_date("09/07/26"),    "09/07/26",   'oe_fmt_date keeps a 2-digit year');
eval { oEdtk::Main::oe_fmt_date("2026-07-09") };
like($@, qr/Unexpected date format/, 'oe_fmt_date dies on an unexpected format');

# --- oe_date_convert : DD/MM/YYYY -> YYYYMMDD -------------------------------
is(oEdtk::Main::oe_date_convert("09/07/2026"), "20260709", 'oe_date_convert converts DD/MM/YYYY');
is(oEdtk::Main::oe_date_convert("9/7/2026"),   "20260709", 'oe_date_convert accepts single digits');
is(oEdtk::Main::oe_date_convert("2026-07-09"), undef,      'oe_date_convert rejects ISO format');
is(oEdtk::Main::oe_date_convert(""),           undef,      'oe_date_convert rejects empty string');
is(oEdtk::Main::oe_date_convert("32/13/2026"), "20261332", 'oe_date_convert does not range-check');

# --- oe_date_compare : KNOWN BUG --------------------------------------------
# Main.pm line 780 computes $wdate2 from $date1 instead of $date2, so the
# comparison always returns 0 for two valid dates.
is(oEdtk::Main::oe_date_compare("01/01/2026", "02/02/2026"), 0,
   'oe_date_compare currently returns 0 for two valid dates');
TODO: {
	local $TODO = 'oe_date_compare uses $date1 twice (Main.pm line 780)';
	is(oEdtk::Main::oe_date_compare("01/01/2026", "02/02/2026"), -1, 'ordered dates compare as -1');
	is(oEdtk::Main::oe_date_compare("01/01/2026", "bad"),        -1, 'bad date2 must be detected');
	is(oEdtk::Main::oe_date_smallest("02/02/2026", "01/01/2026"), "01/01/2026", 'oe_date_smallest');
	is(oEdtk::Main::oe_date_biggest("02/02/2026", "01/01/2026"), "02/02/2026", 'oe_date_biggest');
}

# Behaviours that remain correct despite the bug:
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	is(oEdtk::Main::oe_date_compare("bad", "01/01/2026"), 1, 'bad date1 returns 1');
	like($w[0] // '', qr/Unexpected date format/, '... and warns');
}
is(oEdtk::Main::oe_date_compare("", "02/02/2026"), 0, 'empty date1 is swapped for date2');

done_testing();
