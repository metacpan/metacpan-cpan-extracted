#!/usr/bin/perl -w
#
# $Id: test1.pl,v 1.3 2004/08/25 21:39:59 brian.kaney Exp $
#
# Super simple example using a sample catalog 110 to XML
#

use strict;
use XML::ASCX12;

my $conv = new XML::ASCX12();


#
# (1) Here we pass in file paths for the EDI input and XML output.
#
$conv->convertfile('./INV.110.SAMPLE', './INV.110.SAMPLE.xml');

#
# (2) Here we are inputting binary data.  This could simulate a process
# where the EDI is streamed in from a socket or other non-file location.
#
# If there is a lot of data, it probably would be better to store in a
# file and use the method above.
#
open (TFH, '< ./INV.110.SAMPLE');
binmode(TFH);
my $edi;
while(<TFH>)
{
    $/ = '';
    chomp;
    $edi .= $_;
}
close(TFH);

print $conv->convertdata($edi);

