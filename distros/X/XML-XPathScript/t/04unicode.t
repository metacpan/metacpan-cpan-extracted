#!perl -t

use strict;
use warnings;

use Test::More tests => 11;
use XML::XPathScript;
use XML::XPathScript::Processor qw/ is_utf8_tainted /;

=head1 NAME

04unicode.t - Test Unicode issues (see L<XML::XPathScript/The Unicode
mess>).

=head1 DESCRIPTION

We first test that is_utf8_tainted() works correctly, by comparing
it's result to <Convert::Scalar/utf8> (if Convert::Scalar is
available) against a set of strings whose UTF8ness is known.

=cut


eval { require Convert::Scalar }; # Not fatal if absent

sub ok_utf8_tainted {
    my ($string, $comment) = @_;
    if ($Convert::Scalar::VERSION && ! Convert::Scalar::utf8($string)) {
        is(1, 0, "$comment - Oops, Convert::Scalar disagrees! (error in the test suite)");
        return;
    }
    is(!! XML::XPathScript::Processor->is_utf8_tainted($string), 1, $comment);
}

sub ok_not_utf8_tainted {
    my ($string, $comment) = @_;
    if ($Convert::Scalar::VERSION && Convert::Scalar::utf8($string)) {
        is(1, 0, "$comment - Oops, Convert::Scalar disagrees! (error in the test suite)");
        return;
    }
    is(!!XML::XPathScript::Processor->is_utf8_tainted($string), '', $comment);
}

ok_not_utf8_tainted(" ", "typical plain string");
my $utf8 = do { use utf8; "\x{1e9}" };
ok_utf8_tainted($utf8, "typical UTF-8 string");
my $byte = do { use bytes; substr($utf8, 1) };
ok_not_utf8_tainted($byte,
                    "byte string forcibly extracted from UTF-8 string");

=pod

=head2 Unicode and tainting

There is a fairly serious Perl bug concerning Unicode and taint bits
interacting badly together, for all versions ranging from 5.6.1 to
5.8.4 (look up the history of t/op/utftaint.t in the Perl source
tree). We cater for this too to some extent: we cannot prevent Perl
from SEGVing, but at least is_utf8_tainted() still works and therefore
an appropriate error will be raised when using
C<< XML::XPathScript->current()->binmode() >>.

=cut

my $tainted_null_string = substr($0, 0, 0);
SKIP: {
    no warnings qw/ numeric /;

    local *STDERR;    # if we die, we die silently
    open STDERR, '>', \do { my $anon };

    skip 'Taint mode disabled, UTF8 and taint checks skipped', 3
      if eval { kill 0 => $tainted_null_string; 1 };

    ok_not_utf8_tainted( 'foo' . $tainted_null_string );
    ok_not_utf8_tainted( $byte . $tainted_null_string );
    ok_utf8_tainted( $utf8 . $tainted_null_string );
}

=pod

=head2 Integration with XML::XPathScript->current()->binmode()

We then proceed to testing that the UTF-8 safeguards in the stylesheet
processor work correctly. They are implemented in terms of
is_utf8_tainted().

=cut

use XML::XPathScript;


my $isostring = do {
	no utf8; use bytes; # This is latin1 actually.
    <<"LATIN1_STRING_IN_FRENCH_WITH_MANY_ACCENTS";
O\xf9 qu'il r\xe9side, \xe0 N\xeemes ou m\xeame Capharna\xfcm,
tout Fran\xe7ais inscrit au r\xf4le payera son d\xfb d\xe8s avant
No\xebl, qu'il soit na\xeff ou r\xe2leur
LATIN1_STRING_IN_FRENCH_WITH_MANY_ACCENTS
    # Sorry for the escaping, but we want to keep the test file itself
    # pure-ASCII (so that it won't bugger up in the text editor
    # regardless of i18n settings)
};
ok_not_utf8_tainted($isostring, "real-world Latin1 text");

my $style = <<'STYLE';
<%
enable_binmode();
sub utf8tolatin1 {
	my $orig=shift;
	$orig=$orig->string_value() if (ref($orig) =~ m/^XML::/);

	return pack("C*",grep {$_<255} (unpack("U*",$orig)));
}

$t->{convertok}->{testcode}=sub {
    my ($self, $t)=@_;
    $t->{pre}=utf8tolatin1(findvalue("text()",$self));
    return DO_SELF_ONLY;
};

$t->{convertfail}->{testcode}=sub {
    my ($self, $t)=@_;
    $t->{pre}=findvalue("text()",$self);
    return DO_SELF_ONLY;
};
%><%= apply_templates() %>
STYLE

my $xps = new XML::XPathScript(xml => <<"XML", stylesheet => $style);
<?xml version="1.0" encoding="iso-8859-1" ?>
<convertok>$isostring</convertok>
XML

my $result="";

$xps->process(\$result);
ok_not_utf8_tainted($result,
   "XML::XPathScript->current()->binmode() output not tainted");
ok($result, $isostring."\n");

$xps = new XML::XPathScript(xml => <<"XML", stylesheet => $style);
<?xml version="1.0" encoding="iso-8859-1" ?>
<convertfail>$isostring</convertfail>
XML

$result="";
ok(! eval {$xps->process(\$result); 1}) or warn $result;
ok($@ =~ m/taint/i);

# Dying while STDOUT is butchered by process() is fatal in Perl 5.6.1, so
# please do not add any tests below :-/
