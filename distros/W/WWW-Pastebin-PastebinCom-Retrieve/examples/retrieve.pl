#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';
use WWW::Pastebin::PastebinCom::Retrieve;

die "Usage: perl retrieve.pl <paste_ID_or_URI>\n"
    unless @ARGV;

my $Paste = shift;

my $paster = WWW::Pastebin::PastebinCom::Retrieve->new;

my $results_ref = $paster->retrieve( $Paste )
    or die $paster->error;

printf "Paste content is:\n%s\nPasted by %s on %s\n",
        @$results_ref{ qw(content name posted_on) };
