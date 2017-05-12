#!/bin/perl

################################################################################
# Location: ................... <user defined location>/eBay/API/XML/tools/doc
# File: ....................... genhtmldoc.pl
# Original Author: ............ Bob Bradley
# Last Modifed By: ............ Jeff Nokes
# Last Modified: .............. 03/15/2007 @ 15:01
#
# Description
#
# Generate HTML from POD for the generated classes.
#
################################################################################

use strict;
use warnings;
use HTML::Entities;


my $pod2html = 1;    # Boolean used to determine the type of pod2html processing
                     # we'll perform.  1 = pod2html, 0 = Pod::HtmlEasy.
                     # Default is pod2html.


my $CURRDIR = `pwd`;
chomp($CURRDIR);
chdir('../../../../');
#my $BASEDIR = $ARGV[0] || '../../../..';
my $BASEDIR = `pwd`;
chomp($BASEDIR);

## For debugging use only.
#  print STDERR (
#     '$CURRDIR = ' . $CURRDIR . "\n" .
#     '$BASEDIR = ' . $BASEDIR . "\n"
#  );


# Print intial statement to user that this script is about to try to make html
# documentation from the pod documentation.
  print STDOUT (
     "\n" .
     'Executing script:  ' . __FILE__ . "\n" .
     "\n" .
     'Attempting to generate HTML documentation for all provided pod documentation.' . "\n" .
     "\n"
  );

# Create the docs directory.
  if   (! -d "$BASEDIR/docs")
       {my $rv = `mkdir $BASEDIR/docs`;
       }# end if
  else {print STDERR ("Skipping docs directory creation, as a directory already exists:  $BASEDIR/docs\n\n");
       }# end else


# Check to see if Pod::HtmlEasy is installed.  If it is, then use it, if not, then just use
# good-ol' pod2html.
  eval {
     require Pod::HtmlEasy;
  };# end eval
  if   (!$@)
       {# Then we most likely have Pod::HtmlEasy installed.
          $pod2html = 0;   # Set the boolean appropriately.
        # Echo an informational message that we are using the following pod-2-html parsing.
          print STDOUT (
             "Found Pod::HtmlEasy, using it to produce documentation.  " .
             "(You may see Perl warnings about Pod::HtmlEasy for some reason, but it seems to work.\n\n"
          );
       }# end if
  else {# Echo an informational message that we are using the following pod-2-html parsing.
          print STDOUT ("Cannot find Pod::HtmlEasy, using good-ol' pod2html to produce documentation.\n\n");
       }# end else


# Generate the HTML doc files
my @files = `find $BASEDIR -type f -name '*.pm'`;
foreach my $infile (@files) {
  chomp $infile;
  print STDOUT ('Processing file ' . $infile . '...' . "\n");
  my $basefile = `basename $infile`;
  chomp $basefile;
  my $html = $basefile . ".html";

  my $cmd;
  my $doc;

  # Determine how to create the HTML docs, via the $pod2html boolean.
    if   ($pod2html)
         {
            $cmd = "pod2html --infile=$infile --title=$basefile";
            $doc = `$cmd`;
            $doc = HTML::Entities::decode($doc);
         }# end if
    else {  #require Pod::HtmlEasy;    # Should be available to this script now via the eval above.
            my $podhtml = Pod::HtmlEasy->new() ;
            $doc = $podhtml->pod2html($infile) ;
         }# end else
  
  open (HTML, ">docs/$html")  ||  die('Cannot open document directory for writing!' . "\n");
  print HTML $doc;
  close (HTML);

#  # For debugging use only.
#    sleep(1);
}

# Create the index file
@files = glob("docs/*.html");

@files = sort(@files);
open (INDEX, ">docs/index.html") or die "Cannot open index.html for write.";
print INDEX  "<html><head></head><body><h1>Index of API classes</h1><br/><br/>";
for my $html (@files) {
  chomp $html;
  my $pl = $html;
  $pl =~ s/\.html$//;
  print INDEX "<a href=\"${html}\">${pl}</a><br/>" or die "Cannot write index.html.";
}
print INDEX "</body></html>" or die "Cannot write index.html.";
close (INDEX) or die "Cannot close index.html";

# CD back to the $CURRDIR.
chdir($CURRDIR);

exit 0;
