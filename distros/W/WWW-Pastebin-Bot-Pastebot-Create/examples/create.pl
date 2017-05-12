#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(../lib  lib);

use WWW::Pastebin::Bot::Pastebot::Create;

my $paster = WWW::Pastebin::Bot::Pastebot::Create->new;

$paster->paste( 'testing', summary => 'sorry just testing' )
    or die $paster->error;

print "Your paste is located on $paster\n";