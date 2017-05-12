#!/usr/local/bin/perl -w

# this script produces XML document statistics

use strict;

use XML::DocStats;
use IO::File;

my ($xmlfile,$formp) = @ARGV;
my $format = $formp?$formp:'text';

my $parse;
if ($xmlfile and ($xmlfile ne 'STDIN')) {

  nofile($xmlfile) unless -r $xmlfile;

  my $xmlsource = IO::File->new("< $xmlfile");
  $parse = XML::DocStats->new(xmlsource=>{ByteStream => $xmlsource});
}
else {$parse = XML::DocStats->new;}

$parse->analyze(format=>$format);

exit(0);

sub usage {
    print STDERR <<EOT;
Usage: xmlsaxanalyze [<xmlfile> [html]]
EOT
    exit(0);
}

sub nofile {
my ($xmlfile) = @_;
    print STDERR <<EOT;
xmlsaxanalyze: file '$xmlfile' not readable!
EOT
    usage();
    exit(0);
}
