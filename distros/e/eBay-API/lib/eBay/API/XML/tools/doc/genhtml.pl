################################################################################
# Location: ...................... <user defined location>/eBay/API/XML/tools/doc
# File: .......................... genhtml.pl
# Original Author: ............... Bob Bradley
# Last Modifed By: ............... 
# Last Modified: ................. 10/30/2006
#
# Description
#
# Generate HTML from POD for the generated classes.
################################################################################

use strict;
use  warnings;
use HTML::Entities;

my $BASEDIR="../../../..";

# Generate the HTML doc files
my @files =  `find $BASEDIR -name "*.pm"`;
foreach my $infile (@files) {
  print $infile;
  chomp $infile;
  my $basefile = `basename $infile`;
  chomp $basefile;
  my $html = $basefile . ".html";
  my $cmd = "pod2html --infile=$infile --title=$basefile";
  my $doc = `$cmd`;
  $doc = HTML::Entities::decode($doc);
  open (HTML, ">$html");
  print HTML $doc;
  close (HTML);
}

# Create the index file
@files = glob("*.html");

@files = sort(@files);
open (INDEX, ">index.html") or die "Cannot open index.html for write.";
print INDEX  "<html><head></head><body><h1>Index of API classes</h1><br/><br/>";
for my $html (@files) {
  chomp $html;
  my $pl = $html;
  $pl =~ s/\.html$//;
  print INDEX "<a href=\"${html}\">${pl}</a><br/>" or die "Cannot write index.html.";
}
print INDEX "</body></html>" or die "Cannot write index.html.";
close (INDEX) or die "Cannot close index.html";
exit 0;
