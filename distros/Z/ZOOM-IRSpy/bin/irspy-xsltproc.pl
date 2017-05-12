#!/usr/bin/perl

# This script is only for debugging purposes - it takes a raw IRspy
# xml output document as argument and executes the irspy2zeerex.xsl
# transformation right in front of you:
#
# ./irspy_xsltproc.pl irspy_output_raw.xml ...

use Getopt::Long;
use Data::Dumper;
use lib '../lib';
use ZOOM::IRSpy;

use strict;

#use warnings;

sub usage {

    <<EOF
usage $0 [ options ] file.xml ...

-d		enable xslt debug
-v		verbose level
-f irspy.xsl	set irspy_to_zeerex_xsl
EOF
}

my $irspy_to_zeerex_xsl;
my $xslt_debug;
my $verbose = 0;

GetOptions(
    "d"   => \$xslt_debug,
    "v"   => \$verbose,
    "f=s" => \$irspy_to_zeerex_xsl,
);

die usage if $#ARGV < 0;
XML::LibXSLT->debug_callback( \&xslt_debug ) if defined $xslt_debug;

$ZOOM::IRSpy::irspy_to_zeerex_xsl = $irspy_to_zeerex_xsl
  if $irspy_to_zeerex_xsl;

my $dbname = 'localhost:8018/IR-Explain---1';
my $spy = new ZOOM::IRSpy( $dbname, "admin", "fruitbat" );

warn Dumper($spy) if $verbose;
foreach my $source_file (@ARGV) {
    my $source_doc = $spy->{libxml}->parse_file($source_file);
    my $results    = $spy->{irspy_to_zeerex_style}->transform($source_doc);

    print $results->toString(1);
}

