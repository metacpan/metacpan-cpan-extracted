use Business::myIBAN;
use Test::More;

##
# Test for the package helper to compute an IBAN key, generate and format an
# IBAN from a BBAN and the country code.
#
# @author Vincent Lucas
##

my $alpha_to_digit_src = '12azerty34';
my $alpha_to_digit_res = '1210351427293434';
my $country_code = 'FR';
my $bban = '200410101401867704s0450';
my $iban_key = '06';
my $iban_with_key = 'FR06 2004 1010 1401 8677 04s0 450';

# Test to convert a IBAN with a lower case caracter into digit.
is
    $alpha_to_digit_res
    , ( Business::myIBAN::to_digit $alpha_to_digit_src )
    , "can convert lowercase"; 

# Test to convert a IBAN with a upper case caracter into digit.
$alpha_to_digit_src = uc $alpha_to_digit_src;
is
    $alpha_to_digit_res
    , ( Business::myIBAN::to_digit $alpha_to_digit_src )
    , "can convert uppercase";

# Test to compute a IBAN key.
my $country_code_digit = Business::myIBAN::to_digit($country_code);
my $bban_digit = Business::myIBAN::to_digit($bban);
is
    $iban_key
    , ( Business::myIBAN::compute_key $country_code_digit, $bban_digit )
    , "can compute key"; 

# Test to retrieve an IBAN with it corresponding key from a country code and an
# BBAN.
is
    $iban_with_key
    , ( Business::myIBAN::get_IBAN $country_code, $bban )
    , "can generate a IBAN with it key"; 


done_testing;
