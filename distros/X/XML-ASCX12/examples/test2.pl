#!/perl/bin/perl -w
#
# $Id: test1.pl,v 1.3 2004/08/25 21:39:59 brian.kaney Exp $
#
# Simple example using catalog 175 to XML
#
use lib '../lib'; # before install only
use strict;
use XML::ASCX12;
#
# specify delimiters for catalog 175
# 
my $conv = new XML::ASCX12('\x0A','\x7C');
#
# Sample EDI notices from Appendices to:
#      Electronic Bankruptcy Noticing
#      Trading Partner Implementation Guide
#      October 2003
#
$conv->convertfile('./example_1.edi', './example_1.xml');

$conv->convertfile('./example_2.edi', './example_2.xml');

$conv->convertfile('./example_3.edi', './example_3.xml');
#
# A "real" example with two transaction sets
#
$conv->convertfile('./example_4.edi', './example_4.xml');

