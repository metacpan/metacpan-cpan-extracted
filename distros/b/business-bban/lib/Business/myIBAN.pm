package Business::myIBAN;
use strict;
use warnings;
use 5.010;

=head1 SYNOPSIS

Package helper to compute an IBAN key, generate and format an IBAN from a BBAN
and the country code.

=head2 to_digit $bban=$_

Converts alpha characters into digit, following IBAN rules: replaces each
alpha character with 2 digits A = 10, B = 11, ..., Z = 35.

C<$bban> A string to convert into the IBAN digit representation.

returns a string representation of the Basic Bank Account Number (BBAN), which
contains only digits.

=cut

sub to_digit (_) {
    my $bban = shift;
    $bban = uc $bban;

    $bban =~ s/([A-Z])/(ord $1) - 55/eg;

    $bban;
} 

=head2 compute_key $country_code, $bban

Computes the key corresponding to a given International Bank Account Number
(IBAN) when 

    $country_code A string representation of the country code converted into IBAN  digits.
    $bban A string representation of the Basic Bank Account Number (BBAN)
        with its key part and converted into IBAN digits. 

returns the IBAN key computed.

=cut

sub compute_key {
    my $country_code = shift;
    my $bban = shift;

    my $iban = $bban.$country_code.'00';

    my $rest = 0;
    map { $rest = ($rest * 10 + $_ ) % 97 } split //, $iban;

    my $key = 98 - $rest;
    if($key < 10)
    {
        $key = '0'.$key;
    }

    $key;
} 

=head2 get_IBAN $country_code, $bban

Computes and returns the International Bank Account Number (IBAN)
corresponding to the given country code and Basic Bank Account Number (BBAN).
where

    $country_code is the country code (i.e. "FR" for France, "DE" for Germany, etc.).
    $bban is the Basic Bank Account Number (BBAN).

returns a string representation of the International Bank Account Number
(IBAN) with the key part. The returned IBAN can contains alpha and digit
characters.

=cut

sub get_IBAN {
    my $country_code = uc shift;
    my $bban = shift;

    my $country_code_digit = to_digit($country_code);
    my $bban_digit = to_digit($bban);

    my $iban_key = compute_key($country_code_digit, $bban_digit);

    format_with_spaces($country_code.$iban_key.$bban);
}

=head2 format_with_spaces $iban

Formats the IBAN provided and separate each 4 digit with a space.

    $iban an IBAN

returns the IBAN separated each 4 digit with a space.

=cut

sub format_with_spaces {
    my $iban = shift;
    $iban =~ s/ //g;
    # Only works with French account with an IBAN length of 27 characters.
    # The following instruction selects longuest match first: 4 characters if
    # available, else 3 characters.
    join ' ', ($iban =~ /.{3,4}/g);
}

1;
