# -*- perl -*-

my $numTests = 6;

use strict;
use XML::EP ();
use XML::EP::Request::CGI ();
use XML::EP::Test (qw(Test XmlCmp));
use Data::Dumper ();
use File::Spec ();
use IO::Scalar ();

use lib "d:/jwi/xml-ep/blib/lib";

$^W = $| = 1;


sub MakeFile {
    my $file = shift;  my $xml = shift;
    (open(FILE, ">$file") and (print FILE $xml) and close(FILE))
}

print "1..$numTests\n";
my $file = File::Spec->catdir(File::Spec->tmpdir(), "xslt.t.xml");
$ENV{PATH_TRANSLATED} = $file;
my $tmpurl = File::Spec->tmpdir();
$tmpurl =~ s/\\/\//g;


my $ep = XML::EP->new();
Test($ep);

my $request = XML::EP::Request::CGI->new();
Test($request);
$request->Uri("file:///$tmpurl/");

$::title = $::title = 'Title';

my $xml = <<'XML';
<?xml version="1.0" ?>
<?xml-stylesheet href="xslt.t.xsl"?>
<address>
  <name>Jochen</name>
  <zip>70565</zip>
  <city>Stuttgart</city>
</address>
XML
Test(MakeFile($file, $xml)) or print STDERR "Failed to create $file: $!\n";

my $xsl = <<'XSL';
<?xml version="1.0" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/TR/WD-xsl">
  <xsl:template match="/">
    <html><head><title>This is the Title, isn't it?</title></head>
    <body bgcolor="#ffffff"><h1>Yes, it works!</h1>
      <table>
        <tr><th>Name:</th><td><xsl:value-of select="address/name"/></td></tr>
        <tr><th>ZIP:</th><td><xsl:value-of select="address/zip"/></td></tr>
        <tr><th>City:</th><td><xsl:value-of select="address/city"/></td></tr>
      </table>
    </body></html>
  </xsl:template>
</xsl:stylesheet>
XSL
$file = File::Spec->catdir(File::Spec->tmpdir(), "xslt.t.xsl");
Test(MakeFile($file, $xsl)) or print STDERR "Failed to create $file: $!\n";

my $output;
tie *OUTPUT, 'IO::Scalar', \$output;
$request->FileHandle(\*OUTPUT);
my $result = $ep->Handle($request);
Test(!$result) ||
    print Data::Dumper->new([$result])->Indent(1)->Terse(1)->Dump(), "\n";
XmlCmp($output, <<'XML');
content-type: text/html

<html><head><title>This is the Title, isn't it?</title></head>
<body bgcolor="#ffffff"><h1>Yes, it works!</h1>
<table>
  <tr><th>Name:</th><td>Jochen</td></tr>
  <tr><th>ZIP:</th><td>70565</td></tr>
  <tr><th>City:</th><td>Stuttgart</td></tr>
</table>
</body></html>
XML
