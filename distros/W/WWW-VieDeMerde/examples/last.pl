#! /usr/bin/perl -I../lib

use WWW::VieDeMerde;

my $vdm = WWW::VieDeMerde->new();

my $page = shift;
my @last;

if (defined($page)) {
    @last = $vdm->last($page);
}
else {
    @last = $vdm->last();
}

foreach (@last) {
    print $_->texte, "\n\n";
}

