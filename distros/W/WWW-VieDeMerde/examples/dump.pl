#! /usr/bin/perl -I../lib

use WWW::VieDeMerde;

my $vdm = WWW::VieDeMerde->new();

print $vdm->raw_xml('view', 'last');

