package oEdtk::IBAN;
use warnings;
use strict;
use bigint;
use experimental 'switch';
use Carp    qw( carp croak );
use English qw( -no_match_vars );
use Readonly;

Readonly my $IBAN_DIVISOR        => 97;
Readonly my $IBAN_LETTER_A_VALUE => 10;

Readonly my $REPUBLIC_OF_KOSOVO => 'XK';    # extra, specific case not in ISO-3166
Readonly my @ISO_3166 => qw(
	AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BL
	BM BN BO BQ BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV
	CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD
	GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IM
	IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK
	LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW
	MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR
	PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS
	ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM US UY
	UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW
);

sub is_in_list {
	my ( $val, $l ) = @_;
	foreach my $v ( @{$l} ) {
		return 1 if $v eq $val;
	}
	return 0;
}

sub is_valid_country {
	my ($country) = @_;
	return $country eq $REPUBLIC_OF_KOSOVO
		|| is_in_list( $country, \@ISO_3166 );
}

sub is_valid_bic_format {
	my ($str) = @_;
	return $str =~ m/^
        [A-Z][A-Z][A-Z][A-Z]
        [A-Z][A-Z]
        [A-Z\d][A-Z\d]
        (?:[A-Z\d][A-Z\d][A-Z\d])?
      $/sx;
}

sub bic_country {
	my ($str) = @_;
	return substr $str, 4, 2;
}

sub iban_country {
	my ($str) = @_;
	return substr $str, 0, 2;
}

# NATXFRPP
# https://en.wikipedia.org/wiki/ISO_9362#Structure
# the standard costs 38 CHF: https://www.iso.org/standard/60390.html
sub is_valid_bic {
	my ($str) = @_;
	return is_valid_bic_format($str) && is_valid_country( bic_country($str) );
}

# Convert one uppercase letter to its two-digit IBAN value (A -> 10, B -> 11,
# ..., Z -> 35). The fork read the global $1 instead of its own argument, so it
# only ever worked from inside is_valid_iban_checksum's s///e; called directly it
# returned -55. Read $char.
sub iban_letter_to_number {
	my ($char) = @_;
	return sprintf '%02d', ord($char) - ord('A') + $IBAN_LETTER_A_VALUE;
}

# regexp computed with Editique_interne/lab/seb/tool/iban/iban.pl
sub is_valid_iban_format {
	my ($str) = @_;
	return $str =~ m/^(?:
       AD[0-9]{10}[0-9a-zA-Z]{12}
      |AE[0-9]{21}
      |AL[0-9]{10}[0-9a-zA-Z]{16}
      |AT[0-9]{18}
      |AX[0-9]{16}
      |AZ[0-9]{2}[A-Z]{4}[0-9a-zA-Z]{20}
      |BA[0-9]{18}
      |BE[0-9]{14}
      |BG[0-9]{2}[A-Z]{4}[0-9]{6}[0-9a-zA-Z]{8}
      |BH[0-9]{2}[A-Z]{4}[0-9a-zA-Z]{14}
      |BL[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |BR[0-9]{25}[A-Z]{1}[0-9a-zA-Z]{1}
      |BY[0-9]{2}[0-9a-zA-Z]{4}[0-9]{4}[0-9a-zA-Z]{16}
      |CH[0-9]{7}[0-9a-zA-Z]{12}
      |CR[0-9]{20}
      |CY[0-9]{10}[0-9a-zA-Z]{16}
      |CZ[0-9]{22}
      |DE[0-9]{20}
      |DK[0-9]{16}
      |DO[0-9]{2}[0-9a-zA-Z]{4}[0-9]{20}
      |EE[0-9]{18}
      |ES[0-9]{22}
      |FI[0-9]{16}
      |FO[0-9]{16}
      |FR[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |GB[0-9]{2}[A-Z]{4}[0-9]{14}
      |GE[0-9]{2}[A-Z]{2}[0-9]{16}
      |GF[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |GG[0-9]{2}[A-Z]{4}[0-9]{14}
      |GI[0-9]{2}[A-Z]{4}[0-9a-zA-Z]{15}
      |GL[0-9]{16}
      |GP[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |GR[0-9]{9}[0-9a-zA-Z]{16}
      |GT[0-9]{2}[0-9a-zA-Z]{24}
      |HR[0-9]{19}
      |HU[0-9]{26}
      |IE[0-9]{2}[A-Z]{4}[0-9]{14}
      |IL[0-9]{21}
      |IM[0-9]{2}[A-Z]{4}[0-9]{14}
      |IQ[0-9]{2}[A-Z]{4}[0-9]{15}
      |IS[0-9]{24}
      |IT[0-9]{2}[A-Z]{1}[0-9]{10}[0-9a-zA-Z]{12}
      |JE[0-9]{2}[A-Z]{4}[0-9]{14}
      |JO[0-9]{2}[A-Z]{4}[0-9]{4}[0-9a-zA-Z]{18}
      |KW[0-9]{2}[A-Z]{4}[0-9a-zA-Z]{22}
      |KZ[0-9]{5}[0-9a-zA-Z]{13}
      |LB[0-9]{6}[0-9a-zA-Z]{20}
      |LC[0-9]{2}[A-Z]{4}[0-9a-zA-Z]{24}
      |LI[0-9]{7}[0-9a-zA-Z]{12}
      |LT[0-9]{18}
      |LU[0-9]{5}[0-9a-zA-Z]{13}
      |LV[0-9]{2}[A-Z]{4}[0-9a-zA-Z]{13}
      |MC[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |MD[0-9]{2}[0-9a-zA-Z]{20}
      |ME[0-9]{20}
      |MF[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |MK[0-9]{5}[0-9a-zA-Z]{10}[0-9]{2}
      |MQ[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |MR[0-9]{25}
      |MT[0-9]{2}[A-Z]{4}[0-9]{5}[0-9a-zA-Z]{18}
      |MU[0-9]{2}[A-Z]{4}[0-9]{19}[A-Z]{3}
      |NC[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |NL[0-9]{2}[A-Z]{4}[0-9]{10}
      |NO[0-9]{13}
      |PF[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |PK[0-9]{2}[A-Z]{4}[0-9a-zA-Z]{16}
      |PL[0-9]{26}
      |PM[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |PS[0-9]{2}[A-Z]{4}[0-9a-zA-Z]{21}
      |PT[0-9]{23}
      |QA[0-9]{2}[A-Z]{4}[0-9a-zA-Z]{21}
      |RE[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |RO[0-9]{2}[A-Z]{4}[0-9a-zA-Z]{16}
      |RS[0-9]{20}
      |SA[0-9]{4}[0-9a-zA-Z]{18}
      |SC[0-9]{2}[A-Z]{4}[0-9]{20}[A-Z]{3}
      |SE[0-9]{22}
      |SI[0-9]{17}
      |SK[0-9]{22}
      |SM[0-9]{2}[A-Z]{1}[0-9]{10}[0-9a-zA-Z]{12}
      |ST[0-9]{23}
      |SV[0-9]{2}[A-Z]{4}[0-9]{20}
      |TF[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |TL[0-9]{21}
      |TN[0-9]{22}
      |TR[0-9]{8}[0-9a-zA-Z]{16}
      |UA[0-9]{8}[0-9a-zA-Z]{19}
      |VA[0-9]{20}
      |VG[0-9]{2}[A-Z]{4}[0-9]{16}
      |WF[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
      |XK[0-9]{18}
      |YT[0-9]{12}[0-9a-zA-Z]{11}[0-9]{2}
     )$/sx;
}

# ex: FR7630006000011234567890189
# https://en.wikipedia.org/wiki/IBAN#Validating_the_IBAN
sub is_valid_iban_checksum {
	my ($str)  = @_;
	my $prefix = substr $str, 0, 4;
	my $rest   = substr $str, 4;
	my $tmp    = $rest . $prefix;
	$tmp =~ s{([A-Z])}{iban_letter_to_number($1)}gsex;
	my $n   = 0 + $tmp;             # convert to bigint
	my $mod = $n % $IBAN_DIVISOR;
	return $mod == 1;
}

sub is_valid_iban {
	my ($str) = @_;
	return is_valid_iban_format($str) && is_valid_iban_checksum($str);
}

# https://www.swift.com/file/55811/download?token=Qng75mq9
# page 6
sub is_credible_iban {
	my ($str) = @_;
	return $str =~ m/^[A-Z]{2}[0-9]{2}[A-Za-z0-9]{0,30}$/sx;
}

sub iban_error {
	my ($str) = @_;
	return 'IBAN does not match common format' if !is_credible_iban($str);
	return 'IBAN references an unknown country'
		if !is_valid_country( iban_country($str) );
	return 'IBAN does not follow its country format'
		if !is_valid_iban_format($str);
	return q{}
		if $str =~
		m{[a-z]}sx;    # checksums with lower case letters not implemented yet (standard not found)
	return 'IBAN checksum invalid' if !is_valid_iban_checksum($str);
	return q{};
}

sub bic_error {
	my ($str) = @_;
	return 'BIC does not match common format' if !is_valid_bic_format($str);
	return 'BIC references an unknown country'
		if !is_valid_country( bic_country($str) );
	return q{};
}

# bigint is only needed above; disabling it here keeps the module's final "1;"
# from being a void-context constant, which would otherwise emit
# "Useless use of a constant (1)" under use warnings.
no bigint;

1;

=head1 NAME

oEdtk::IBAN - validate IBAN and BIC identifiers

=head1 SYNOPSIS

    use oEdtk::IBAN;

    my $err = oEdtk::IBAN::iban_error($iban);
    # '' when the IBAN is valid, otherwise a human readable reason
    $err = oEdtk::IBAN::bic_error($bic);

=head1 DESCRIPTION

Pure-Perl validation of International Bank Account Numbers (IBAN) and Bank
Identifier Codes (BIC), following the ISO-13616 and ISO-9362 structures.

Every function is called fully qualified (the module exports nothing). The
C<*_error> functions return an empty string when their argument is valid and a
short English message otherwise, so a caller can decide whether to warn or
reject without catching exceptions.

The fork shipped this module at version 0.8032; it was moved unmodified into the
mainline at S20 of the fork-merge plan, save for a fix to
C<iban_letter_to_number> (see L</BUGS>).

=head1 FUNCTIONS

=head2 iban_error

    my $reason = iban_error($iban);

Run every IBAN check in order and return the first failure, or C<''>. Checks, in
order: the general shape (L</is_credible_iban>), the country code
(L</is_valid_country>), the country-specific format (L</is_valid_iban_format>)
and finally the checksum (L</is_valid_iban_checksum>). An IBAN containing lower
case letters is accepted without a checksum check, because the lower case
checksum is not implemented.

=head2 bic_error

    my $reason = bic_error($bic);

Return C<''> when the BIC has both a valid shape and a known country code, and a
message otherwise.

=head2 is_valid_iban

    my $ok = is_valid_iban($iban);

True when the IBAN matches its country format I<and> its checksum is valid.

=head2 is_valid_iban_format

    my $ok = is_valid_iban_format($iban);

True when the IBAN matches the length and structure registered for its country.

=head2 is_valid_iban_checksum

    my $ok = is_valid_iban_checksum($iban);

True when the IBAN passes the ISO-13616 mod-97 checksum. The letters are folded
to digits via L</iban_letter_to_number> and the arithmetic uses C<bigint>.

=head2 is_credible_iban

    my $ok = is_credible_iban($iban);

Cheap shape check: two uppercase letters, two digits and up to thirty
alphanumeric characters.

=head2 iban_country / bic_country

    my $cc = iban_country($iban);   # first two characters
    my $cc = bic_country($bic);     # characters 5 and 6

Extract the country code from an IBAN or a BIC.

=head2 is_valid_country

    my $ok = is_valid_country($cc);

True when C<$cc> is an ISO-3166 alpha-2 code, or XK (Kosovo, a widely used code
that is absent from ISO-3166).

=head2 is_valid_bic

    my $ok = is_valid_bic($bic);

True when the BIC has a valid shape and a known country code.

=head2 is_valid_bic_format

    my $ok = is_valid_bic_format($bic);

True when the BIC follows the ISO-9362 structure: four letters (bank), two
letters (country), two alphanumeric (location) and an optional three-character
alphanumeric branch.

=head2 iban_letter_to_number

    my $two_digits = iban_letter_to_number($char);

Convert one uppercase letter to its two-digit IBAN value (A -> C<10>, B -> C<11>,
..., Z -> C<35>).

=head2 is_in_list

    my $ok = is_in_list($value, \@list);

Helpers: true when C<$value> equals one element of C<\@list>.

=head1 BUGS

The fork version of C<iban_letter_to_number> read the global C<$1> instead of its
argument. It worked by accident inside C<is_valid_iban_checksum>, where C<$1>
was set by the enclosing C<s///e>, and returned C<-55> for any letter when called
directly. The port reads C<$char>; see F<t/int/30_iban.t>.

=head1 AUTHOR

The oEdtk team.

=cut
