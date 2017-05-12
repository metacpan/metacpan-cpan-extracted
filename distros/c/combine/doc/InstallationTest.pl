use strict;
if ( $> != 0 ) {
    die("You have to run this test as root");
}

my $orec='';
while (<DATA>) { chop; $orec .= $_; }

$orec =~ s|<checkedDate>.*</checkedDate>||;
$orec =~ tr/\n\t //d;

my $olen=length($orec);
my $onodes=0;
while ( $orec =~ m/</g ) { $onodes++; }
print "ORIG Nodes=$onodes; Len=$olen\n";

our $jobname;
require './t/defs.pm';

system("combineINIT --jobname $jobname --topic /etc/combine/Topic_carnivor.txt > /dev/null");

system("combine --jobname $jobname --harvest http://combine.it.lth.se/CombineTests/InstallationTest.html");
open(REC,"combineExport --jobname $jobname |");
my $rec='';
while (<REC>) { chop; $rec .= $_; }
close(REC);
$rec =~ s|<checkedDate>.*</checkedDate>||;
$rec =~ tr/\n\t //d;

my $len=length($rec);
my $nodes=0;
while ( $rec =~ m/</g ) { $nodes++; }
print "NEW Nodes=$nodes; Len=$len\n";

my $OK=0;

if ($onodes == $nodes) { print "Number of XML nodes match\n"; }
else { print "Number of XML nodes does NOT match\n"; $OK=1; }
if ($olen == $len) {
  print "Size of XML match\n";
} else {
  $orec =~  s|<originalDocument.*</originalDocument>||s;
  $rec =~  s|<originalDocument.*</originalDocument>||s;
  if (length($orec) == length($rec)) { print "Size of XML match (after removal of 'originalDocument')\n";}
  else { print "Size of XML does NOT match\n"; $OK=1; }
}

if (($OK == 0) && ($orec eq $rec)) { print "All tests OK\n"; }
else { print "There might be some problem with your Combine Installation\n"; }

__END__
<?xml version="1.0" encoding="UTF-8"?>
<documentCollection version="1.1" xmlns="http://alvis.info/enriched/">
<documentRecord id="80AC707F96BC57DFEF78C815F6FABD57">
<acquisition>
<acquisitionData>
<modifiedDate>2006-12-05 13:20:25</modifiedDate>
<checkedDate>2006-10-03 9:06:42</checkedDate>
<httpServer>Apache/1.3.29 (Debian GNU/Linux) PHP/4.3.3</httpServer>
<urls>
    <url>http://combine.it.lth.se/CombineTests/InstallationTest.html</url>
  </urls>
</acquisitionData>
<originalDocument mimeType="text/html" compression="gzip" encoding="base64" charSet="UTF-8">
H4sIAAAAAAAAA4WQsU7DMBCG9zzF4bmpBV2QcDKQVKJSKR2CEKObXBSrjm3sSyFvT0yCQGJgusG/
//u+E1flU1G9HrfwUD3u4fh8v98VwFLOXzYF52VVzg+b9Q3n2wPLE9FRr+NA2UyDFGnMdyaQ1FqS
sgYIA0FrPRS2PymDgs+hRPRIEozsMWNnHN+tbwKD2hpCQxkrpDfqYr0dAjgtDYUVlN4G9HIFB3RT
qMPAvns6Ipfi26Au09e5I61Gh78aCT+IR947qDvpA1I2UJvexg6+CJxsM0ad6/8kpkQiXB5XSWUC
BNsj/GGG4LBWrarhSw+0OiOIidZjmzGPeh15WL6ICS7zFUjT/AiuBXeRbwHj870/AeRYaTupAQAA
</originalDocument>
<canonicalDocument>  
  <section>
    <section title="Installation test for Combine">
      <section>Installation test for Combine</section> 
      <section>Contains some Carnivorous plant specific words like <ulink url="rel.html">Drosera </ulink>, and Nepenthes.</section></section></section></canonicalDocument>
<metaData>
    <meta name="title">Installation test for Combine</meta>
    <meta name="dc:format">text/html</meta>
    <meta name="dc:format">text/html; charset=iso-8859-1</meta>
    <meta name="dc:subject">Carnivorous plants</meta>
    <meta name="dc:subject">Drosera</meta>
    <meta name="dc:subject">Nepenthes</meta>
  </metaData>
<links>
    <outlinks>
      <link type="a">
        <anchorText>Drosera</anchorText>
        <location>http://combine.it.lth.se/CombineTests/rel.html</location>
      </link>
    </outlinks>
  </links>
<analysis>
<property name="topLevelDomain">se</property>
<property name="univ">1</property>
<property name="language">en</property>
<topic absoluteScore="1000" relativeScore="110526">
    <class>ALL</class>
  </topic>
<topic absoluteScore="375" relativeScore="41447">
    <class>CP.Drosera</class>
    <terms>drosera</terms>
  </topic>
<topic absoluteScore="375" relativeScore="41447">
    <class>CP.Nepenthes</class>
    <terms>nepenthe</terms>
  </topic>
<topic absoluteScore="250" relativeScore="27632">
    <class>CP</class>
    <terms>carnivorous plant</terms>
    <terms>carnivor</terms>
  </topic>
</analysis>
</acquisition>
</documentRecord>

</documentCollection>
