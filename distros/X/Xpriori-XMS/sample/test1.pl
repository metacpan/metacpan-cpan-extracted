#!c:/perl/bin/perl -w
use lib qw(../lib);
use strict;
use Xpriori::XMS::Http;

my $oXpH = new Xpriori::XMS::Http(
    'http://localhost:7700', 'Administrator', 'admin');

#deleteXML
$oXpH->deleteXML('/ND/blog');

#storeXML
open IN, '<', 'sampleXML/blog.xml';
my $sXml= join('', <IN>);
close IN;
my $sRes = $oXpH->storeXML($sXml);
print ">>> storeXML:\n$sRes\n";

#storeXML_File
$sRes = $oXpH->storeXML_File('sampleXML/blog2.xml');
print ">>> storeXML_File:\n$sRes\n";

#queryXML
$sRes = $oXpH->queryXML('/ND/blog/entries/entry/title');
print ">>> queryXML:\n$sRes\n";

#queryFlatXML
$sRes = $oXpH->queryFlatXML('/ND/blog/entries/entry');
print ">>> queryFlatXML:\n$sRes\n";

#queryTreeXML
$sRes = $oXpH->queryTreeXML('/ND/blog/entries/entry');
print ">>> queryTreeXML:\n$sRes\n";

#count
$sRes = $oXpH->queryCountXML('/ND/blog/entries/entry');
print ">>> queryCountXML:\n$sRes\n";

#count(not acid)
$sRes = $oXpH->queryCountXML('/ND/blog/entries/entry', 1);
print ">>> queryCountXML(not acid):\n$sRes\n";

#logout
$oXpH->logout();
