#!c:/perl/bin/perl -w
use strict;
use lib qw(../lib);
use Xpriori::XMS::Http;

my $oXpH = new Xpriori::XMS::Http(
    'http://localhost:7700', 'Administrator', 'admin');

my $sRes;
$sRes = $oXpH->deleteXML('/ND/test');
$sRes = $oXpH->storeXML('<test><A/><XYZ>xyz</XYZ></test>');

$sRes = $oXpH->setIsolationLevel('READ_UNCOMMITTED');
$sRes = $oXpH->startTransaction();
$sRes = $oXpH->queryXMLUpdateIntent('/ND/test/A');
print ">>> queryXMLUpdateIntent:\n" . $sRes;
print 'FOR WAIT for LOCK:';
my $sIn = <STDIN>;
$sRes = $oXpH->commitTransaction();
