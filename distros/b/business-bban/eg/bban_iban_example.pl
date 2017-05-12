#!/usr/bin/perl

use Modern::Perl;
use Business::BBAN;
use Business::myIBAN;
use Locale::Country;

##
# Very short exemple on how to use BBAN and IBAN packages.
#
# @author Vincent Lucas
##


my $country = 'France';
my $bank_id = "20041";
my $bank_location_id = "01014";
my $account_id = "01867704s04";

my $country_code = country2code($country);
my $bban = Business::BBAN::get_BBAN($bank_id, $bank_location_id, $account_id);
my $iban = Business::myIBAN::get_IBAN($country_code, $bban);

print "res: 
        \tbban: $bban
        \tiban: $iban
        \n";
