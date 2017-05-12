#!perl -w

use strict;

use Data::Dumper;
use WebService::Postcodeanywhere::BACS::REST;

my $license_key = 'xxxx';
my $account_code = 'xxxx';

WebService::Postcodeanywhere::BACS::REST->license_code($license_key);
WebService::Postcodeanywhere::BACS::REST->account_code($account_code);

my $sortcode = '12-34-56';

print "\ngetting branch details for $sortcode\n";

my $details = WebService::Postcodeanywhere::BACS::REST->getBACSFromSortCode($sortcode);

print "\n..got details\n";

print Dumper(%$details);


