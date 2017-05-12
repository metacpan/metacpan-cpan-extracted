#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';
use WWW::Pastebin::Many::Retrieve;

my $paster = WWW::Pastebin::Many::Retrieve->new;

my @pastes = qw(
    http://pastebin.ca/963177
    http://pastebin.com/d2fbd2737
    http://www.nomorepasting.com/getpaste.php?pasteid=10124
    http://pastie.caboo.se/172741
    http://phpfi.com/302683
    http://rafb.net/p/XU5KMo65.html
    http://paste.ubuntu-nl.org/61578/
);

for ( @pastes ) {
    print "Processing paste $_\n";

    $paster->retrieve( $_ )
        or warn $paster->error
        and next;

    print "Content on $_ is:\n$paster\n";
}
