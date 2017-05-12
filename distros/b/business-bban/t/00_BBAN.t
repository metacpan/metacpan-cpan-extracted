use Business::BBAN;
use Test::More;

##
# Test for the package helper to compute BBAN key and generate an BBAN from a
# bank identifier, a bank location identifier and an account identifier.
#
# @author Vincent Lucas
##

my $bank_id = '20041';
my $bank_location_id = '01014';
my $account_id = '01867704s04';
my $bban_src = $bank_id.$bank_location_id.$account_id;
my $bban_digit = '200410101401867704204';
my $bban_key = '50';
my $bban_with_key = $bban_src.$bban_key;

# Test to convert a bban with a lower case caracter into digit.
is
    $bban_digit
    , ( Business::BBAN::to_digit $bban_src )
    , "can convert lowercase"; 

# Test to convert a bban with a upper case caracter into digit.
$bban_src = uc $bban_src;
is
    $bban_digit
    , ( Business::BBAN::to_digit $bban_src )
    , "can convert uppercase";

# Test to compute a bban key.
is
    $bban_key
    , ( Business::BBAN::compute_key $bban_digit )
    , "can compute key"; 

# Test to retrieve a BBAN with it corresponding key from a bank identifier, a
# bank location identifier and an account identifier.
is
    $bban_with_key
    , ( Business::BBAN::get_BBAN $bank_id, $bank_location_id, $account_id )
    , "can generate a BBAN with it key"; 


done_testing;
