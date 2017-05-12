# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01dcl.t'

#########################

use Test::More tests => 23;
BEGIN { use_ok('XML::DTD') };

#########################

my $dtd = new XML::DTD;
my $cmnt = "<!-- A comment -->";
ok($dtd->sread($cmnt));
is($dtd->swrite(), $cmnt);

$dtd = new XML::DTD;
my $elmt = "<!ELEMENT a (#PCDATA)>";
ok($dtd->sread($elmt));
is($dtd->swrite(), $elmt);

$dtd = new XML::DTD;
my $attr = "<!ATTLIST a b CDATA #IMPLIED>";
ok($dtd->sread($attr));
is($dtd->swrite(), $attr);

$dtd = new XML::DTD;
my $enty = "<!ENTITY a \"bcd\">";
ok($dtd->sread($enty));
is($dtd->swrite(), $enty);

$dtd = new XML::DTD;
$enty = "<!ENTITY % Text \"#PCDATA\">";
ok($dtd->sread($enty));
is($dtd->swrite(), $enty);

$dtd = new XML::DTD;
$enty = "<!ENTITY % a SYSTEM \"filename\">";
ok($dtd->sread($enty));
is($dtd->swrite(), $enty);

$dtd = new XML::DTD;
$enty = "<!ENTITY % b PUBLIC \"+//D//E//EN\" \"filename\">";
ok($dtd->sread($enty));
is($dtd->swrite(), $enty);

$dtd = new XML::DTD;
my $ignr = "<![ IGNORE [ <ELEMENT b (#PCDATA)> ]]>";
ok($dtd->sread($ignr));
is($dtd->swrite(), $ignr);

$dtd = new XML::DTD;
my $incl = "<![ INCLUDE [ <ELEMENT c (#PCDATA)> ]]>";
ok($dtd->sread($incl));
is($dtd->swrite(), $incl);

$dtd = new XML::DTD;
my $notn = "<!NOTATION e PUBLIC \"+//F//G//EN\">";
ok($dtd->sread($notn));
is($dtd->swrite(), $notn);

$dtd = new XML::DTD;
my $pi = "<?h i?>";
ok($dtd->sread($pi));
is($dtd->swrite(), $pi);
