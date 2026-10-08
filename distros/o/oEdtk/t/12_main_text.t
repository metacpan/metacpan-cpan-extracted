#!/usr/bin/perl
#
# Non-regression tests for the string/encoding helpers of oEdtk::Main.
#
# Accented bytes are written literally as "\xE9" etc. (ISO-8859-1), which is
# what the oEdtk modules expect. This file stays pure ASCII.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use TestOEdtk qw(quiet_require);

quiet_require('oEdtk::Main');

# --- oe_trimp_space : collapse runs of whitespace ---------------------------
my $s = "a   b";
is(oEdtk::Main::oe_trimp_space(\$s), "a b", 'oe_trimp_space collapses inner blanks');
is($s, "a b", 'oe_trimp_space mutates its argument');
$s = "  x";
is(oEdtk::Main::oe_trimp_space(\$s), " x", 'oe_trimp_space collapses leading blanks');

# --- oe_uc_sans_accents : upper-case + strip accents ------------------------
$s = "\xE9\xE0\xE7\xFB";   # e-acute, a-grave, c-cedilla, u-circumflex
is(oEdtk::Main::oe_uc_sans_accents(\$s), "EACU", 'oe_uc_sans_accents strips lower-case accents');
$s = " caf\xE9 ";
is(oEdtk::Main::oe_uc_sans_accents(\$s), " CAFE ", 'oe_uc_sans_accents keeps spaces');

# --- oe_CAP_sans_accents : strip only upper-case accents --------------------
$s = "\xC9\xC0\xC7";       # E-acute, A-grave, C-cedilla
is(oEdtk::Main::oe_CAP_sans_accents(\$s), "EAC", 'oe_CAP_sans_accents strips upper-case accents');
$s = "caf\xE9";            # lower-case e-acute must be left untouched
is(oEdtk::Main::oe_CAP_sans_accents(\$s), "caf\xE9", 'oe_CAP_sans_accents keeps lower-case accents');

# --- toC7date ---------------------------------------------------------------
$s = "20260709";
is(oEdtk::Main::toC7date(\$s), "<C7j>09<C7m>07<C7a>2026", 'toC7date builds the C7 date tag');
is($s, "<C7j>09<C7m>07<C7a>2026", 'toC7date mutates its argument');

# --- c7Flux -----------------------------------------------------------------
$s = "<A>";
is(oEdtk::Main::c7Flux(\$s), 1, 'c7Flux returns 1 (constant), not the string');
is($s, "{A}", 'c7Flux replaces angle brackets with braces');

# --- oe_env_var_completion --------------------------------------------------
SKIP: {
	skip 'POSIX \$-expansion test skipped on Windows', 1 if $^O eq 'MSWin32';
	local $ENV{OEDTK_TST12} = 'xyz';
	$s = 'a$OEDTK_TST12/b';
	is(oEdtk::Main::oe_env_var_completion(\$s), 'axyz/b', 'oe_env_var_completion expands $VAR');
}

done_testing();
