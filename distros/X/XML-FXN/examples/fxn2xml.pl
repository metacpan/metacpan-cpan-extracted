#!/usr/bin/perl

use strict;
use warnings;
use XML::FXN;

my $file_path = shift or die "usage: $0 fxn_file \n";

undef $/;
open( FXN_DOCUMENT, "< $file_path" )
 or die "fxn2xml: Can not open the file $file_path ($!).\n";
print fxn2xml( <FXN_DOCUMENT> );
exit


