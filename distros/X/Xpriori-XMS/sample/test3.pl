#!c:/perl/bin/perl -w
use lib qw(../lib);
use strict;
use Xpriori::XMS::Http;

my $oXpH = new Xpriori::XMS::Http(
    'http://localhost:7700', 'Administrator', 'admin');
my $sRes;

#VERSION
$sRes = $oXpH->getServerVersion();
print ">>> VER\n" . $sRes;
#STATICTICS
$sRes = $oXpH->getServerStatistics();
print ">>> NO0\n" . $sRes;
$sRes = $oXpH->getServerStatistics('ADMIN');
print ">>> NO1\n" . $sRes;
$sRes = $oXpH->getServerStatistics('STORAGE');
print ">>> NO2\n" . $sRes;
$sRes = $oXpH->getServerStatistics('ACCESS');
print ">>> NO3\n" . $sRes;
$sRes = $oXpH->getServerStatistics('BUFFER');
print ">>> NO4\n" . $sRes;
$sRes = $oXpH->getServerStatistics('TRANSACTION');
print ">>> NO5\n" . $sRes;
$sRes = $oXpH->getServerStatistics('WINDOW');
print ">>> NO6\n" . $sRes;

$sRes = $oXpH->clearServerStatistics();
print ">>> NO7\n" . $sRes;
$sRes = $oXpH->getServerStatistics('ACCESS');
print ">>> NO8\n" . $sRes;
