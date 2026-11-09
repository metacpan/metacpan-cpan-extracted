package Validator::LIVR::Rules::Special;

use strict;
use warnings;

our $VERSION = '2.22';

# From 0 to 255. Leading zeros are allowed, as Validator::LIVR 2.0 allowed them in URLs
my $IPV4_OCTET = qr/25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9]/;

# Letters, digits and hyphens, but not a hyphen at the start or the end. Up to 63 characters
my $EMAIL_LABEL = qr/[a-zA-Z0-9] (?: [a-zA-Z0-9-]{0,61} [a-zA-Z0-9] )?/x;

# The TLD starts with a letter, as the last label of a host name in "url"
my $EMAIL_TLD = qr/[a-zA-Z] (?: [a-zA-Z0-9-]{0,61} [a-zA-Z0-9] )?/x;

# As in the other LIVR implementations, the local part is dot-separated atoms or a quoted
# string, and the domain is a host name or an IP address in brackets.
# \z, not $: "$" also matches before a trailing newline
my $EMAIL_RE = qr/\A
    (?:
        [^<>()\[\]\\.,;:\s\@"\x00-\x1f\x7f]+ (?: \.[^<>()\[\]\\.,;:\s\@"\x00-\x1f\x7f]+ )*
      | " (?: [^"\\\@\x00-\x1f\x7f\x{2028}\x{2029}] | \\[^\x00-\x1f\x7f\x{2028}\x{2029}] )+ "
    )
    \@
    (?:
        \[ $IPV4_OCTET (?: \.$IPV4_OCTET ){3} \]
      | (?: $EMAIL_LABEL \. )+ $EMAIL_TLD
    )
\z/x;

sub email {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        # The local part is up to 64 characters, the address up to 254. "@" is not in the local part
        return 'WRONG_EMAIL' if length($value) > 254 || index($value, '@') > 64;
        return 'WRONG_EMAIL' unless $value =~ $EMAIL_RE;
        return;
    };
}


sub equal_to_field {
    my $field = shift;

    return sub {
        my ( $value, $params ) = @_;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        return 'FIELDS_NOT_EQUAL' unless defined( $params->{$field} ) && $value eq $params->{$field};
        return;
    };
}


# Letters of any language, digits and hyphens, but not a hyphen at the start or the end.
# Up to 63 characters. "." is not in a label, so labels do not overlap
my $URL_LABEL = qr/[a-z0-9\x{a1}-\x{10ffff}] (?: [a-z0-9\x{a1}-\x{10ffff}-]{0,61} [a-z0-9\x{a1}-\x{10ffff}] )?/xi;

# The last label starts with a letter, so a host name is never an IP address
my $URL_LAST_LABEL = qr/[a-z\x{a1}-\x{10ffff}] (?: [a-z0-9\x{a1}-\x{10ffff}-]{0,61} [a-z0-9\x{a1}-\x{10ffff}] )?/xi;

my $URL_HOST = qr/ $IPV4_OCTET (?: \.$IPV4_OCTET ){3} | (?: $URL_LABEL \. )* $URL_LAST_LABEL /x;

# From 0 to 65535, with 1-5 digits
my $URL_PORT = qr/ [0-9]{1,4} | [0-5][0-9]{4} | 6[0-4][0-9]{3} | 65[0-4][0-9]{2} | 655[0-2][0-9] | 6553[0-5] /x;

# An http or https URL with a host name or an IPv4 address, and an optional user, port,
# path, query and fragment. As in Validator::LIVR 2.0, and unlike the other LIVR
# implementations, a host name can be without a TLD, such as "intranet", any IPv4
# address is allowed, and the length is not limited. As in LIVR 2.5, there is no dot
# after the host, a label has up to 63 characters and a port is at most 65535.
#
# It is "https?:// (?: \S+\@ )? $URL_HOST (?: :$URL_PORT )? (?: [\/?\#] \S* )? \z" in two
# cases. The user can end at any "@" of the value, and in each case the path is matched
# once, not again for every "@":
#  - Without spaces: the path, the query and the fragment are anything after a "/", "?"
#    or "#" that follows the host
#  - With spaces, which can only be in the host (labels have the characters from U+00A1
#    on, and some of them are spaces, such as U+3000): the user ends at the last "@"
#    before the first space
my $URL_RE = qr/\A
    https?:\/\/
    (?:
        (?= \S* \z )
        (?: \S+\@ )? $URL_HOST (?: :$URL_PORT )? (?: [\/?\#] | \z )
      |
        (?: \S+\@ (?= [^\s\@\/?\#]* \s ) )? $URL_HOST (?: :$URL_PORT )? (?: [\/?\#] \S* )? \z
    )
/xi;

sub url {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        return 'WRONG_URL' unless $value =~ $URL_RE;
        return;
    };
}


# \z, not $: "$" also matches before a trailing newline
my $ISO_DATE_RE = qr#^
    (?<year>[0-9]{4})-
    (?<month>[0-1][0-9])-
    (?<day>[0-3][0-9])
\z#x;

sub iso_date {
    # LIVR 2.5: the first argument, if any, is an object with the bounds "min" and "max".
    # LIVR 2.0 ignored any argument. { iso_date => undef } has no arguments
    if ( @_ > 2 || @_ == 2 && defined( $_[0] ) ) {
        require Validator::LIVR::Rules::DateTime;
        goto &Validator::LIVR::Rules::DateTime::iso_date;
    }

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';

        # LIVR 2.5: a boolean is a primitive value, not a date
        return ref($value) =~ /Boolean/ ? 'WRONG_DATE' : 'FORMAT_ERROR' if ref($value);

        if ( $value =~ $ISO_DATE_RE ) {
            my ( $year, $month, $day ) = @+{qw/year month day/};
            return "WRONG_DATE" if $month < 1 || $month > 12;

            my $is_leap_year = ( $year % 4 == 0 && $year % 100 != 0 ) || $year % 400 == 0;
            my $max_day = ( 31, $is_leap_year ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 )[ $month - 1 ];

            return if $day >= 1 && $day <= $max_day;
        }

        return "WRONG_DATE";
    };
}

1;

=head1 NAME

Validator::LIVR::Rules::Special - Special rules of Validator::LIVR: email, url, iso_date and equal_to_field

=head1 DESCRIPTION

This module has the code of the special rules, which are documented in
L<Validator::LIVR/Special rules>.

Each sub is the builder of the rule with the same name. The code is a good
example for L<writing your own rules|Validator::LIVR/WRITING RULES IN PERL>.

=cut
