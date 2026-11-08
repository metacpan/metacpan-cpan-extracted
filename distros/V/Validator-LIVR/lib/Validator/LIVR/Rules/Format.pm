package Validator::LIVR::Rules::Format;

use strict;
use warnings;

use Validator::LIVR::Rules::Types;

our $VERSION = '2.21';

# LIVR 2.5: formats and checksums. They check the string form of a string or a number and
# output it. A boolean gets the error code of the rule (true is not a hostname, "true" is), a
# hash or a list gets FORMAT_ERROR. The builder of "hex" is livr_hex, as Perl has hex().
#
# Grammars use ASCII classes and match the whole value: \z, not $, which also matches before a
# trailing newline. Inputs have no length limit, so the regular expressions stay linear

my $HEX = '[0-9a-fA-F]';

# A rule that checks the string form with a regular expression
sub _regex_rule {
    my ( $error_code, $re ) = @_;

    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || $value eq '';

        if ( ref($value) ) {
            return ref($value) =~ /Boolean/ ? $error_code : 'FORMAT_ERROR';
        }

        my $string = Validator::LIVR::Rules::Types::string_form($value);
        return $error_code unless $string =~ $re;

        $$output_ref = $string;
        return;
    };
}

# A rule that checks the string form with a sub
sub _check_rule {
    my ( $error_code, $is_valid ) = @_;

    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || $value eq '';

        if ( ref($value) ) {
            return ref($value) =~ /Boolean/ ? $error_code : 'FORMAT_ERROR';
        }

        my $string = Validator::LIVR::Rules::Types::string_form($value);
        return $error_code unless $is_valid->($string);

        $$output_ref = $string;
        return;
    };
}

sub _no_arguments {
    my $rule_name = shift;
    die "Rule [$rule_name] takes no arguments\n" if @_ > 1;
}

# RFC 9562: the version digit (the first of the third group) is 1-8, the variant digit (the
# first of the fourth group) is 8, 9, a or b. The nil and the max UUID pass only without versions
my $UUID_RE = qr/\A${HEX}{8}-${HEX}{4}-[1-8]${HEX}{3}-[89abAB]${HEX}{3}-${HEX}{12}\z/;
my $ANY_UUID_RE = qr/\A(?:
    ${HEX}{8}-${HEX}{4}-[1-8]${HEX}{3}-[89abAB]${HEX}{3}-${HEX}{12}
  | 00000000-0000-0000-0000-000000000000
  | [fF]{8}-[fF]{4}-[fF]{4}-[fF]{4}-[fF]{12}
)\z/x;

sub uuid {
    my @versions = @_;
    pop @versions; # rule_builders

    return _regex_rule( 'WRONG_UUID', $ANY_UUID_RE ) if !@versions;

    # Versions are strings "v1"-"v8", as in ip and cidr: 4, "4" and "V4" die
    my %is_allowed;
    foreach my $version (@versions) {
        if ( !defined($version) || ref($version) || $version !~ /\Av([1-8])\z/ ) {
            die qq{Rule [uuid] takes versions "v1"-"v8"\n};
        }
        $is_allowed{$1} = 1;
    }

    # The version digit is the 15th character: "xxxxxxxx-xxxx-Vxxx-..."
    return _check_rule( 'WRONG_UUID', sub { $_[0] =~ $UUID_RE && $is_allowed{ substr( $_[0], 14, 1 ) } } );
}

# Four numbers 0-255 without leading zeros: some systems read "010" as octal
my $IPV4_OCTET = qr/25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9]/;
my $IPV4_RE = qr/\A(?:$IPV4_OCTET)(?:\.(?:$IPV4_OCTET)){3}\z/;
my $HEX_GROUP_RE = qr/\A${HEX}{1,4}\z/;

# The number of 16-bit groups in a part of an IPv6 address: hex groups separated by ":", the
# last one may be an IPv4 address (two groups) at the end of the address. -1 for a wrong group
sub _count_ipv6_groups {
    my ( $part, $is_address_end ) = @_;
    return 0 if $part eq '';

    my @groups = split /:/, $part, -1;
    my $last = pop @groups;

    foreach my $group (@groups) {
        return -1 unless $group =~ $HEX_GROUP_RE;
    }

    return @groups + 1 if $last =~ $HEX_GROUP_RE;
    return @groups + 2 if $is_address_end && $last =~ $IPV4_RE;
    return -1;
}

# RFC 4291, section 2.2: eight groups, or fewer with one "::" for one or more groups of zeros.
# No zone ID, brackets or prefix length
sub _is_ipv6 {
    my $address = shift;

    # The longest form is 8 groups of 4 digits with an IPv4 address in the last two
    return 0 if length($address) > 45;

    my $gap = index( $address, '::' );
    return _count_ipv6_groups( $address, 1 ) == 8 if $gap < 0;

    # A second "::" (":::" too) is ambiguous
    return 0 if index( $address, '::', $gap + 1 ) >= 0;

    my $before = _count_ipv6_groups( substr( $address, 0, $gap ), 0 );
    my $after  = _count_ipv6_groups( substr( $address, $gap + 2 ), 1 );
    return $before >= 0 && $after >= 0 && $before + $after <= 7;
}

# "v4" or "v6" as 4 or 6, 0 for both
sub _ip_version {
    my $rule_name = shift;
    my @args = @_;
    pop @args; # rule_builders

    return 0 if !@args;

    # Arguments after the version are ignored
    if ( defined( $args[0] ) && !ref( $args[0] ) ) {
        return 4 if $args[0] eq 'v4';
        return 6 if $args[0] eq 'v6';
    }

    die qq{Rule [$rule_name] takes no arguments, "v4" or "v6"\n};
}

sub ip {
    my $version = _ip_version( 'ip', @_ );

    return _regex_rule( 'WRONG_IP', $IPV4_RE ) if $version == 4;
    return _check_rule( 'WRONG_IP', \&_is_ipv6 ) if $version == 6;
    return _check_rule( 'WRONG_IP', sub { $_[0] =~ $IPV4_RE || _is_ipv6( $_[0] ) } );
}

# A prefix length: decimal without leading zeros
my $PREFIX_LENGTH_RE = qr/\A(?:0|[1-9][0-9]{0,2})\z/;

sub cidr {
    my $version = _ip_version( 'cidr', @_ );

    # Host bits may be set: "10.0.0.1/8" passes
    return _check_rule( 'WRONG_CIDR', sub {
        my $slash = index( $_[0], '/' );
        return 0 if $slash < 0;

        my $address = substr( $_[0], 0, $slash );
        my $prefix_length = substr( $_[0], $slash + 1 );
        return 0 unless $prefix_length =~ $PREFIX_LENGTH_RE;

        return $prefix_length <= 32  if $version != 6 && $address =~ $IPV4_RE;
        return $prefix_length <= 128 if $version != 4 && _is_ipv6($address);
        return 0;
    } );
}

# RFC 1123: labels of 1-63 characters, not starting or ending with "-", no trailing dot.
# "." is not in a label, so labels do not backtrack into each other
my $HOSTNAME_RE = qr/\A
    [a-zA-Z0-9] (?: [a-zA-Z0-9-]{0,61} [a-zA-Z0-9] )?
    (?: \. [a-zA-Z0-9] (?: [a-zA-Z0-9-]{0,61} [a-zA-Z0-9] )? )*
\z/x;

sub hostname {
    _no_arguments( 'hostname', @_ );

    # Labels may be all digits, except the last one (RFC 1123, section 2.1): "192.0.2.1" and
    # "123" are not hostnames
    return _check_rule( 'WRONG_HOSTNAME', sub {
        return length( $_[0] ) <= 253
            && $_[0] =~ $HOSTNAME_RE
            && substr( $_[0], rindex( $_[0], '.' ) + 1 ) =~ /[^0-9]/;
    } );
}

# RFC 4648. A character class with "*" and the length checked apart: (?:X{4})* fails on
# long values in old versions of Perl
my $BASE64_RE     = qr/\A[A-Za-z0-9+\/]*(={0,2})\z/;
my $BASE64_URL_RE = qr/\A[A-Za-z0-9_-]*(={0,2})\z/;

sub base64 {
    my @args = @_;
    pop @args; # rule_builders

    # The standard alphabet: the length is a multiple of 4, the padding "=" or "==" only at the end
    return _check_rule( 'WRONG_BASE64', sub { $_[0] =~ $BASE64_RE && length( $_[0] ) % 4 == 0 } ) if !@args;

    if ( defined( $args[0] ) && !ref( $args[0] ) && $args[0] eq 'url' ) {
        # The URL-safe alphabet, the padding is optional: either complete or absent. A lone
        # character in the last group is never valid
        return _check_rule( 'WRONG_BASE64', sub {
            return 0 unless $_[0] =~ $BASE64_URL_RE;
            return length( $1 ) ? length( $_[0] ) % 4 == 0 : length( $_[0] ) % 4 != 1;
        } );
    }

    die qq{Rule [base64] takes no arguments or "url"\n};
}

# No "0x" prefix
my $HEX_RE = qr/\A$HEX+\z/;

sub livr_hex {
    _no_arguments( 'hex', @_ );
    return _regex_rule( 'WRONG_HEX', $HEX_RE );
}

my %HEX_LENGTH_OF = ( md5 => 32, sha1 => 40, sha256 => 64, sha384 => 96, sha512 => 128 );

sub digest {
    my @algorithms = @_;
    pop @algorithms; # rule_builders

    die "Rule [digest] needs one or more algorithms\n" if !@algorithms;

    my %is_length;
    foreach my $algorithm (@algorithms) {
        if ( !defined($algorithm) || ref($algorithm) || !$HEX_LENGTH_OF{$algorithm} ) {
            die qq{Rule [digest] takes "md5", "sha1", "sha256", "sha384" or "sha512"\n};
        }
        $is_length{ $HEX_LENGTH_OF{$algorithm} } = 1;
    }

    return _check_rule( 'WRONG_DIGEST', sub { $is_length{ length( $_[0] ) } && $_[0] =~ $HEX_RE } );
}

# A BSON ObjectId: 12 bytes in hex
sub mongo_id {
    _no_arguments( 'mongo_id', @_ );
    return _regex_rule( 'WRONG_MONGO_ID', qr/\A${HEX}{24}\z/ );
}

# #RGB, #RGBA, #RRGGBB or #RRGGBBAA
sub hex_color {
    _no_arguments( 'hex_color', @_ );
    return _regex_rule( 'WRONG_HEX_COLOR', qr/\A#(?:${HEX}{3,4}|${HEX}{6}|${HEX}{8})\z/ );
}

# Hex pairs separated by ":" or by "-": the back reference keeps the first separator.
# 48 bits are six pairs (MAC-48, EUI-48), 64 bits are eight pairs (EUI-64)
my %MAC_RE = (
    48 => qr/\A${HEX}{2}([:-])${HEX}{2}(?:\1${HEX}{2}){4}\z/,
    64 => qr/\A${HEX}{2}([:-])${HEX}{2}(?:\1${HEX}{2}){6}\z/,
);

sub mac {
    my @args = @_;
    pop @args; # rule_builders

    # A bit count, "48" is 48. Arguments after it are ignored
    my $bits = @args ? $args[0] : 48;
    if ( !Validator::LIVR::Rules::Types::is_length($bits) || !$MAC_RE{ $bits + 0 } ) {
        die "Rule [mac] takes no arguments, 48 or 64\n";
    }

    return _regex_rule( 'WRONG_MAC', $MAC_RE{ $bits + 0 } );
}

# "+", then 7-15 digits, the first is not 0
sub e164 {
    _no_arguments( 'e164', @_ );
    return _regex_rule( 'WRONG_E164', qr/\A\+[1-9][0-9]{6,14}\z/ );
}

# The regular expression of semver.org 2.0.0, with [0-9] for \d
my $SEMVER_NUMBER = '(?:0|[1-9][0-9]*)';
my $SEMVER_PRE_ID = "(?:$SEMVER_NUMBER|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)";
my $SEMVER_RE = qr/\A
    $SEMVER_NUMBER \. $SEMVER_NUMBER \. $SEMVER_NUMBER
    (?: - $SEMVER_PRE_ID (?: \. $SEMVER_PRE_ID )* )?
    (?: \+ [0-9a-zA-Z-]+ (?: \. [0-9a-zA-Z-]+ )* )?
\z/x;

sub semver {
    _no_arguments( 'semver', @_ );
    return _regex_rule( 'WRONG_SEMVER', $SEMVER_RE );
}

# The structure of a JWS compact serialization: header.payload.signature in base64url without
# padding, the signature is empty in an unsecured JWT. The segments are not decoded
my $JWT_RE = qr/\A([A-Za-z0-9_-]+)\.([A-Za-z0-9_-]+)\.([A-Za-z0-9_-]*)\z/;

sub jwt {
    _no_arguments( 'jwt', @_ );

    # No base64url segment has a length of 1 modulo 4: such a length cannot come from bytes
    return _check_rule( 'WRONG_JWT', sub {
        return $_[0] =~ $JWT_RE && length($1) % 4 != 1 && length($2) % 4 != 1 && length($3) % 4 != 1;
    } );
}

# Luhn mod 10: every second digit from the right is doubled, minus 9 when above 9
sub _has_luhn_checksum {
    my $digits = shift;
    my ( $sum, $is_doubled ) = ( 0, 0 );

    for ( my $i = length($digits) - 1; $i >= 0; $i-- ) {
        my $digit = substr( $digits, $i, 1 );

        if ($is_doubled) {
            $digit *= 2;
            $digit -= 9 if $digit > 9;
        }

        $sum += $digit;
        $is_doubled = !$is_doubled;
    }

    return $sum % 10 == 0;
}

# The string form is checked as it is: no spaces or dashes are removed
sub luhn {
    _no_arguments( 'luhn', @_ );
    return _check_rule( 'WRONG_CHECKSUM', sub { $_[0] =~ /\A[0-9]{2,}\z/ && _has_luhn_checksum( $_[0] ) } );
}

# ISO/IEC 7812 card numbers have 12-19 digits. No card network detection
sub credit_card {
    _no_arguments( 'credit_card', @_ );
    return _check_rule( 'WRONG_CREDIT_CARD_NUMBER', sub { $_[0] =~ /\A[0-9]{12,19}\z/ && _has_luhn_checksum( $_[0] ) } );
}

# ISO 13616: a country code, two check digits, 11-30 characters. No per-country length table.
# The first four characters moved to the end, letters replaced by two digits (A = 10 ... Z = 35):
# the number modulo 97 is 1. The remainder is computed a character at a time, so the number
# stays small
sub _has_iban_checksum {
    my $iban = shift;
    my $remainder = 0;

    foreach my $code ( unpack 'C*', substr( $iban, 4 ) . substr( $iban, 0, 4 ) ) {
        $remainder = $code <= 57
            ? ( $remainder * 10 + $code - 48 ) % 97
            : ( $remainder * 100 + $code - 55 ) % 97;
    }

    return $remainder == 1;
}

sub iban {
    _no_arguments( 'iban', @_ );
    return _check_rule( 'WRONG_IBAN', sub { $_[0] =~ /\A[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}\z/ && _has_iban_checksum( $_[0] ) } );
}

1;

=head1 NAME

Validator::LIVR::Rules::Format - LIVR 2.5 format and checksum rules of Validator::LIVR: uuid, ip, cidr, hostname, base64, hex, digest, mongo_id, hex_color, mac, e164, semver, jwt, luhn, credit_card and iban

=head1 DESCRIPTION

This module has the code of these rules, which are documented in
L<Validator::LIVR/LIVR 2.5 rules>. Validator::LIVR loads it when a validator
uses one of the rules.

Each sub is the builder of the rule with the same name. The builder of C<hex>
is C<livr_hex>, as Perl has C<hex()>.

=cut
