#!/usr/bin/perl

use strict;
use warnings;
use XML::FXN;

my $file_path = shift or die "usage: $0 xml_file \n";

undef $/;
open( XML_DOCUMENT, "< $file_path" )
 or die "xml2fxn: Can not open the file $file_path ($!).\n";
print xml2fxn( <XML_DOCUMENT> );
exit


