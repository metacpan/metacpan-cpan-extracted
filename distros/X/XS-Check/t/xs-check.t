# This is a test for module XS::Check.

use warnings;
use strict;
use Test::More;
use_ok ('XS::Check');
use FindBin '$Bin';
use lib $Bin;
use XSCT;
my $ok = <<EOF;
const char * x;
STRLEN len;
x = SvPVbyte (sv, len);
EOF
got_warning ($ok, "OK XS", 0);

my $len_wrong = <<EOF;
const char * x;
unsigned int len;
x = SvPVutf8 (sv, len);
EOF
got_warning ($len_wrong, "Not STRLEN", 1, qr!STRLEN!);

my $not_const = <<EOF;
char * x;
STRLEN len;
x = SvPVbyte (sv, len);
EOF
got_warning ($not_const, "Not const char *", 1);

my $malloc =<<EOF;
const char * x;
x = malloc (100);
EOF
got_warning ($malloc, "use malloc", 1, qr!malloc!);

my $notfree =<<EOF;
void
DESTROY (tf)
	Text::Fuzzy tf;
CODE:
	text_fuzzy_free (tf);
EOF
got_warning ($notfree, "free in other string", 0);

my $commented =<<EOF;
/* realloc malloc free free (x) */
EOF
got_warning ($commented, "realloc etc. in comment", 0);

my $perl_prefix =<<EOF;
Perl_croak ("croaking");
EOF
got_warning ($perl_prefix, "Perl_ prefix", 1, qr!Perl_!);

my $void_arg =<<'EOF';
MODULE=poo

int
test_arglist(void)
CODE:
    RETVAL = 1;
OUTPUT:
    RETVAL
EOF
my $out = got_warning ($void_arg, "void argument", 1);
like ($out, qr/4:/, "Got correct line number for error");

my $warning;
$SIG{__WARN__} = sub {
    $warning = shift;
};

$warning = undef;
my $checker = XS::Check->new ();
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
}

done_testing ();
