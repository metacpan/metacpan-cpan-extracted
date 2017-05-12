#!c:/perl/bin/perl -w
use strict;
use lib qw(../lib);
use Xpriori::XMS::Http;

#AutoLogout
my $oXpHo = new Xpriori::XMS::Http(
    'http://localhost:7700', 'Administrator', 'admin',
     AUTO_LOGOUT=> 1
    );

# Use Privious Connect
## Original
my $oXpH = new Xpriori::XMS::Http(
    'http://localhost:7700', 'Administrator', 'admin');
my $iSid = $oXpH->getSID();
undef($oXpH);
## Using Original Connect
my $oXpN = new Xpriori::XMS::Http(
             $CstNeoCoreURL, {sid => $iSid});,

# You can combine with AUTO_LOGOUT
# my $oXpN = new Xpriori::XMS::Http(
#             $CstNeoCoreURL, {sid => $iSid}, AUTO_LOGOUT => 1);,

