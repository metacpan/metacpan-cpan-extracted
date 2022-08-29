#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML::xmlsec;

my $signer=XML::LibXML::xmlsec->new();

$signer->loadpkey(PEM => 'key.pem', secret => 'the watcher and the tower');

