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

$warning = undef;
$checker->check (<<EOF);
/* realloc malloc free free (x) */
EOF
ok (! $warning, "No warning with 'realloc' in a comment");

$warning = undef;
$checker->check (<<'EOF');
Perl_croak ("croaking");
EOF
ok ($warning, "Got a warning with Perl_croak");

$warning = undef;
$checker->check (<<'EOF');
MODULE=poo

int
test_arglist(void)
CODE:
    RETVAL = 1;
OUTPUT:
    RETVAL
EOF
ok ($warning, "Got a warning with void argument to function");
like ($warning, qr/4:/, "Got correct line number for error");
$warning = undef;
$checker->check (<<'EOF');
MODULE=poo

int
test_arglist(void)
{
EOF
ok (! $warning, "Got no warning with void argument to C function");

my %rstuff;

sub reporter
{
    %rstuff = @_;
}

my $rchecker = XS::Check->new (reporter => \& reporter);
ok ($rchecker->{reporter}, "Field added OK");
$warning = undef;
$rchecker->check (<<'EOF');
Perl_croak ("croaking");
EOF
ok (! defined ($warning), "did not issue a warning");
ok ($rstuff{message}, "got a message");
ok ($rstuff{line} == 1, "got a line number");
ok (! $rstuff{file}, "No file name for inline thing");
%rstuff = ();

$warning = undef;
my $badchecker = XS::Check->new (reporter => 'doughnuts');
ok ($warning, "warning from bad reporter value");
like ($warning, qr/code reference/, "correct warning");

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
