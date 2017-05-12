#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(lib);

# VERSION

die "Usage: perl retrieve.pl <paste_ID_or_URI>\n"
    unless @ARGV;

my $Paste = shift;

use lib '../lib';
use WWW::Pastebin::PastebinCa::Retrieve;

my $paster = WWW::Pastebin::PastebinCa::Retrieve->new;

my $content_ref = $paster->retrieve( $Paste )
    or die "Failed to retrieve paste $Paste: " . $paster->error;

printf qq|Posted on "%s", titled "%s" and description|
            . qq| is "%s"\n\n%s\n|,
         @$content_ref{ qw(post_date  name  desc  content ) };

print "Content: \n$paster\n";
