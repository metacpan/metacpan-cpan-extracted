package Exception::BadArguments::InvalidJSON;
$Exception::BadArguments::InvalidJSON::VERSION = '2.5';
use base qw(Exception::BadArguments);

=head1 Name

qbit::StringUtils - Functions to manipulate strings.

=cut

package qbit::StringUtils;
$qbit::StringUtils::VERSION = '2.5';
use strict;
use warnings;
use utf8;

use qbit::GetText;
use qbit::Exceptions;

use base qw(Exporter);

use HTML::Entities;
use URI::Escape qw(uri_escape_utf8);
use Net::LibIDN qw(idn_to_unicode idn_to_ascii);
use JSON::XS ();
use POSIX qw(locale_h);

BEGIN {
    our (@EXPORT, @EXPORT_OK);

    @EXPORT = qw(
      html_encode html_decode uri_escape check_email idn_to_unicode get_domain to_json from_json format_number fix_utf
      );
    @EXPORT_OK = @EXPORT;
}

my $RFC822PAT = <<'EOF';
[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\
xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xf
f\n\015()]*)*\)[\040\t]*)*(?:(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\x
ff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|"[^\\\x80-\xff\n\015
"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015"]*)*")[\040\t]*(?:\([^\\\x80-\
xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80
-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*
)*(?:\.[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\
\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\
x80-\xff\n\015()]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x8
0-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|"[^\\\x80-\xff\n
\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015"]*)*")[\040\t]*(?:\([^\\\x
80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^
\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040
\t]*)*)*@[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([
^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\
\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\
x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-
\xff\n\015\[\]]|\\[^\x80-\xff])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()
]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\
x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:\.[\04
0\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\
n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\
015()]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?!
[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\
]]|\\[^\x80-\xff])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\
x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\01
5()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*)*|(?:[^(\040)<>@,;:".
\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]
)|"[^\\\x80-\xff\n\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015"]*)*")[^
()<>@,;:".\\\[\]\x80-\xff\000-\010\012-\037]*(?:(?:\([^\\\x80-\xff\n\0
15()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][
^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)|"[^\\\x80-\xff\
n\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015"]*)*")[^()<>@,;:".\\\[\]\
x80-\xff\000-\010\012-\037]*)*<[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?
:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-
\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:@[\040\t]*
(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015
()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()
]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\0
40)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\
[^\x80-\xff])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\
xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*
)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:\.[\040\t]*(?:\([^\\\x80
-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x
80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t
]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\
\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])
*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x
80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80
-\xff\n\015()]*)*\)[\040\t]*)*)*(?:,[\040\t]*(?:\([^\\\x80-\xff\n\015(
)]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\
\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*@[\040\t
]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\0
15()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015
()]*)*\)[\040\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(
\040)<>@,;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|
\\[^\x80-\xff])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80
-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()
]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:\.[\040\t]*(?:\([^\\\x
80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^
\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040
\t]*)*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".
\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff
])*\])[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\
\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x
80-\xff\n\015()]*)*\)[\040\t]*)*)*)*:[\040\t]*(?:\([^\\\x80-\xff\n\015
()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\
\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*)?(?:[^
(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-
\037\x80-\xff])|"[^\\\x80-\xff\n\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\
n\015"]*)*")[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|
\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))
[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:\.[\040\t]*(?:\([^\\\x80-\xff
\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\x
ff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(
?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\
000-\037\x80-\xff])|"[^\\\x80-\xff\n\015"]*(?:\\[^\x80-\xff][^\\\x80-\
xff\n\015"]*)*")[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\x
ff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)
*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*)*@[\040\t]*(?:\([^\\\x80-\x
ff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-
\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)
*(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\
]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])*\]
)[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-
\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\x
ff\n\015()]*)*\)[\040\t]*)*(?:\.[\040\t]*(?:\([^\\\x80-\xff\n\015()]*(
?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]*(?:\\[^\x80-\xff][^\\\x80
-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)*\)[\040\t]*)*(?:[^(\040)<
>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000-\037\x8
0-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])*\])[\040\t]*(?:
\([^\\\x80-\xff\n\015()]*(?:(?:\\[^\x80-\xff]|\([^\\\x80-\xff\n\015()]
*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015()]*)*\))[^\\\x80-\xff\n\015()]*)
*\)[\040\t]*)*)*>)
EOF
$RFC822PAT =~ s/\n//g;

my $DOMAIN_PART_RE = '[^:\s\/\.!@#$%^&*()\[\]\{\}\?\+;\'"`\\\\]+';

=head1 Functions

=head2 html_encode

B<Arguments:>

=over

=item

B<$str> - string.

=back

B<Return value:> string with encoded HTML entities.

=cut

sub html_encode($) {
    return defined($_[0]) ? encode_entities($_[0]) : '';
}

=head2 html_decode

B<Arguments:>

=over

=item

B<$str> - string.

=back

B<Return value:> string with decoded HTML entities.

=cut

sub html_decode($) {
    return defined($_[0]) ? decode_entities($_[0]) : '';
}

=head2 uri_escape

B<Arguments:>

=over

=item

B<$str> - string.

=back

B<Return value:> string with escaped URI entities.

=cut

sub uri_escape($) {
    return uri_escape_utf8($_[0]);
}

=head2 check_email

B<Arguments:>

=over

=item

B<$email> - string, E-Mail.

=back

B<Return value:> boolean, TRUE if email is valid.

=cut

sub check_email($) {
    my ($email) = @_;

    return $email =~ /^$RFC822PAT$/;
}

=head2 get_domain

B<Arguments:>

=over

=item

B<$url> - string, URL;

=item

B<%opts> - additional arguments:

=over

=item

B<ascii> - boolean, convert unicode chars to ascii;

=item

B<www> - boolean, save 'www.'.

=back

=back

B<Return value:> string if domain valid, else nothing.

=cut

sub get_domain($;%) {
    my ($url, %opts) = @_;

    my $www = $opts{'www'} ? '' : '(?:www\.)?';

    $url = lc($url);
    $url =~ s/(^\s+)|(\s+$)//g;

    if ($url =~ /^(?:https?:\/\/)?$www((?:$DOMAIN_PART_RE\.)*$DOMAIN_PART_RE)\.?($|\/|:\d+|\?)/) {
        my $res = $opts{'ascii'} ? idn_to_ascii($1, 'utf-8') : idn_to_unicode($1, 'utf-8');
        utf8::decode($res);
        return $res;
    } else {
        return;
    }
}

=head2 to_json

B<Arguments:>

=over

=item

B<$data> - scalar.

=back

B<Return value:> string, C<$data> as JSON.

=cut

sub to_json($;%) {
    my ($data, %opts) = @_;

    my $res;

    if ($opts{'pretty'}) {
        $res = JSON::XS->new->utf8->allow_nonref->pretty->canonical->encode($data);
    } else {
        $res = JSON::XS->new->utf8->allow_nonref->encode($data);
    }

    utf8::decode($res);

    return $res;
}

=head2 from_json

B<Arguments:>

=over

=item

B<$text> - string, JSON.

=back

B<Return value:> scalar, perl structure from JSON.

=cut

sub from_json($) {
    my ($text) = @_;

    my $original_text = $text;

    utf8::encode($text);
    my $result;
    eval {$result = JSON::XS->new->utf8->allow_nonref->decode($text);};

    if (!$@) {
        return $result;
    } else {
        $text = '' if !defined $text;
        my ($error) = ($@ =~ m'(.+) at /');
        $error ||= $@;
        throw Exception::BadArguments::InvalidJSON gettext("Error in from_json: %s\n" . "Input:\n" . "'%s'\n", $error,
            $original_text,);
    }
}

=head2 format_number

B<Arguments:>

=over

=item

B<$number> - number;

=item

B<%args> - hash, additional arguments:

=over

=item

B<precision>: number, needed precision, if missed then frac will return as is;

B<thousands_sep>: string, thousands separator, default gets from locale;

B<decimal_point>: string, decimal point, default gets from locale.

=back

=back

B<Return value:> string, formatted number.

=cut

sub format_number($%) {
    my ($number, %opts) = @_;

    my $fmt_precision = ($opts{'precision'} || 0) + 1;
    $number = sprintf("%.${fmt_precision}f", $number)
      if $number =~ /^(-?[\d.]+)e([+-]\d+)$/;    # Convert exponent notation

    my $old_locale;
    if (defined($ENV{'LC_ALL'})) {
        $old_locale = setlocale(LC_NUMERIC);
        setlocale(LC_NUMERIC, "$ENV{'LC_ALL'}.utf8");
    }

    my $localeconv = localeconv();
    my $half       = 0.50000000000008;

    foreach my $opt (qw(thousands_sep decimal_point)) {
        unless (defined($opts{$opt})) {
            $opts{$opt} = $localeconv->{$opt};
            utf8::decode($opts{$opt});
        }
    }

    setlocale(LC_NUMERIC, $old_locale) if $old_locale;

    my ($minus, $int, $frac_zero, $frac) =
      $number =~ /^(-?)(\d+)(?:[^\d](0*)(\d*))?$/
      ? ($1, int($2), $3, int($4 || 0))
      : throw Exception::BadArguments gettext('Invalid number "%s"', $number);

    $frac_zero = '' unless defined($frac_zero);

    if (defined($opts{'precision'})) {
        if ($opts{'precision'} == 0) {
            ++$int if substr($frac, 0, 1) >= 5;
            $frac = '';
        } else {
            $frac = int("0.$frac_zero$frac" * (10**$opts{'precision'}) + $half);
            $frac = substr("$frac_zero$frac", 0, $opts{'precision'});
            $frac = "$opts{'decimal_point'}$frac" . ('0' x ($opts{'precision'} - length($frac)));
        }
    } else {
        $frac = $frac == 0 ? '' : "$opts{'decimal_point'}$frac_zero$frac";
    }

    if (length($int) > 3) {
        $int = reverse($int);
        $int =~ s/(\d\d\d)(?!$)/$1$opts{'thousands_sep'}/g;
        $int = reverse($int);
    }

    return "$minus$int$frac";
}

=head2 fix_utf

B<Arguments:>

=over

=item

B<$string> - string.

=back

Convert $string to perl utf8 string if it is without utf8 flag;

B<Return value:> string with utf8 flag.

=cut

sub fix_utf {
    my ($string) = @_;

    utf8::decode($string) unless utf8::is_utf8($string);

    return $string;
}

1;
