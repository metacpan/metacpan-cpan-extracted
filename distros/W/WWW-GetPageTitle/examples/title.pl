#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(lib ../lib);

@ARGV
    or die "Usage: perl $0 uri1 uri2 uri3\n";

use WWW::GetPageTitle;

my $t = WWW::GetPageTitle->new;

for ( @ARGV ) {
    $t->get_title($_)
        or printf "ERROR: %s\n" . $t->error
        and next;

    printf "Title for %s is %s\n", $t->uri, $t->title;
}