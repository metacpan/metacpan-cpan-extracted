#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML::xmlsec;

my $signer=XML::LibXML::xmlsec->new();

print $signer->XmlSecVersion."\n";




