#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(../lib lib);
use WWW::Pastebin::PastebinCa::Create;

my $paster = WWW::Pastebin::PastebinCa::Create->new;

$paster->paste('testing', expire => '5 minutes' )
    or die $paster->error;

printf "Your paste can be found on %s\n", $paster->paste_uri;