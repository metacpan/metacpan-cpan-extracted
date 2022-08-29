#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML::xmlsec;

my $signer=XML::LibXML::xmlsec->new();

$signer->loadpkey(PFX => 'esf.pfx', secret => 'watcher');


my $doc=XML::LibXML->load_xml(location => 'hello-ready.xml');
print $doc->toString(1);

my @list=$doc->findnodes("//ds:Signature");

$signer->signdoc($doc,  'node' => $list[0], 'id-node' => 'Data', 'id-attr' => 'id');
#$signer->signdoc($doc, id => "hello");
print $doc->toString(1);
