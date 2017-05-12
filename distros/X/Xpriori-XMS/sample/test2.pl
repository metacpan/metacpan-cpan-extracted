#!c:/perl/bin/perl -w
use strict;
use lib qw(../lib);
use Xpriori::XMS::Http;

my $oXpH = new Xpriori::XMS::Http(
    'http://localhost:7700', 'Administrator', 'admin');

my $sRes;
$sRes = $oXpH->deleteXML('/ND/test');
print "RES1: $sRes\n";
$sRes = $oXpH->storeXML('<test><A/></test>');
print "RES2: $sRes\n";
$sRes = $oXpH->insertXML('/ND/test/A', '<XYZ>xyz</XYZ>');
print "RES3: $sRes\n";
$sRes = $oXpH->queryXML('/ND/test/');
print "RES4: $sRes\n";
$sRes = $oXpH->modifyXML('/ND/test/XYZ', '<XYZ>modify</XYZ>');
print "RES4: $sRes\n";
$sRes = $oXpH->queryXML('/ND/test');
print "RES4: $sRes\n";

#insertXML_File
$oXpH->deleteXML('/ND/sample');
$oXpH->storeXML('<sample><base/></sample>');
$sRes = $oXpH->insertXML_File('/ND/sample/base', 'sampleXML/insFile.xml');
print ">>> insertXML_File:\n" . $sRes;
$sRes = $oXpH->queryXML('/ND/sample');
print ">>> queryXML:\n" . $sRes;

#modifyXML_File
$sRes = $oXpH->modifyXML_File('/ND/sample/test', 'sampleXML/modFile.xml');
print ">>> modifyXML_File:\n" . $sRes;
$sRes = $oXpH->queryXML('/ND/sample');
print ">>> queryXML:\n" . $sRes;

$sRes = $oXpH->deleteXML('/ND/test');
$sRes = $oXpH->storeXML('<test><A/></test>');
$sRes = $oXpH->queryXML('/ND/test');
print "RES0: $sRes\n";

$sRes = $oXpH->setIsolationLevel('READ_UNCOMMITTED');
print "RES1: $sRes\n";

$sRes = $oXpH->startTransaction();
print "RES2: $sRes\n";

$sRes = $oXpH->insertXML('/ND/test/A', '<XYZ>xyz</XYZ>');
print "RES3: $sRes\n";
$sRes = $oXpH->queryXML('/ND/test');
print "RES4: $sRes\n";

$sRes = $oXpH->rollbackTransaction();
print "RES5: $sRes\n";

$sRes = $oXpH->queryXML('/ND/test');
print "RES6: $sRes\n";

$sRes = $oXpH->startTransaction();
print "RES7: $sRes\n";

$sRes = $oXpH->insertXML('/ND/test/A', '<XYZ>xyz</XYZ>');
print "RES8: $sRes\n";
$sRes = $oXpH->queryXMLUpdateIntent('/ND/test/A');
print "RES8-1: $sRes\n";

$sRes = $oXpH->commitTransaction();
print "RES9: $sRes\n";

$sRes = $oXpH->queryXML('/ND/test');
print "RES10: $sRes\n";


$sRes = $oXpH->queryXML('/ND');
print "RES10: $sRes\n";
#copyXML
$sRes = $oXpH->deleteXML('/ND/test');
$sRes = $oXpH->storeXML('<test><A/></test>');
$sRes = $oXpH->copyXML('/ND/test/..');
print "RES10: $sRes\n";
$sRes = $oXpH->queryXML('/ND/test');
print "RES10: $sRes\n";
