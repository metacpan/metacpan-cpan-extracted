#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML::xmlsec;

my $signer=XML::LibXML::xmlsec->new();

$signer->loadpkey(PFX => 'esf.pfx', secret => 'watcher');
$signer->KeysStoreSave('keystore.xml',XML::LibXML::xmlsec::xmlSecKeyDataTypeAny);
