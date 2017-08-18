# This is a test for module XS::Check.

use warnings;
use strict;
use Test::More;
use_ok ('XS::Check');
use XS::Check;
my $warning;
$SIG{__WARN__} = sub {
$warning = shift;
};
my $checker = XS::Check->new ();
$checker->check (<<EOF);
const char * x;
STRLEN len;
x = SvPV (sv, len);
EOF
ok (! $warning, "No warning with OK code");
$warning = undef;
$checker->check (<<EOF);
const char * x;
unsigned int len;
x = SvPV (sv, len);
EOF
ok ($warning, "Warning with not STRLEN");
$warning = undef;
$checker->check (<<EOF);
char * x;
STRLEN len;
x = SvPV (sv, len);
EOF
ok ($warning, "Warning with not const char *");
$warning = undef;
$checker->check (<<EOF);
const char * x;
x = malloc (100);
EOF
ok ($warning, "Warning with malloc");

$warning = undef;
$checker->check (<<EOF);
void
DESTROY (tf)
	Text::Fuzzy tf;
CODE:
	text_fuzzy_free (tf);
EOF
ok (! $warning, "No warning with 'free' embedded in another string");

TODO: {
local $TODO='read function arguments';
$warning = undef;
$checker->check (<<'EOF');
static void
sv_to_text_fuzzy (SV * text, STRLEN length)
{
    const unsigned char * stuff;
    /* Copy the string in "text" into "text_fuzzy". */
    stuff = (unsigned char *) SvPV (text, length);
EOF
ok (! $warning, "No warning with variable from function argument");
};

done_testing ();
# Local variables:
# mode: perl
# End:
