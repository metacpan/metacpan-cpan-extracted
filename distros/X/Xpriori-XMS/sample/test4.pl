#!c:/perl/bin/perl -w
use strict;
use lib qw(../lib);
use Xpriori::XMS::Http;

my $oXpH = new Xpriori::XMS::Http(
    'http://localhost:7700', 'Administrator', 'admin');
my $sRes;
#Trace Level
$sRes = $oXpH->getTraceLevels();
print ">>> getTraceLeveles\n" . $sRes;
$sRes = $oXpH->setTraceLevels('INFO:LOG_Performance');
print ">>> setTraceLeveles\n" . $sRes;
$sRes = $oXpH->getTraceLevels();
print ">>> getTraceLeveles(2)\n" . $sRes;

#AccessControl
$sRes = $oXpH->activateAccessControl();
print ">>> activateAccessControl:\n" .$sRes;

#Password
$sRes = $oXpH->setPassword('Administrator', 'admin_');
print ">>> setPassword:\n" .$sRes;
eval {
  my $oXpH2 = new Xpriori::XMS::Http(
    'http://localhost:7700', 'Administrator', 'admin');
};
print ">>> ERROR:\n" .$@;

$sRes = $oXpH->setPassword('Administrator', 'admin');
print ">>> setPassword:\n" .$sRes;
