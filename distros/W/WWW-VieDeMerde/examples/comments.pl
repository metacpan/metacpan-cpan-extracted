#! /usr/bin/perl -I../lib

use WWW::VieDeMerde;

my $vdm = WWW::VieDeMerde->new();
my $id = shift;

my $item = $vdm->get($id);
die unless defined($item);
print $item->text, "\n";
print $item->id, "\n\n";

my @comments = $vdm->comments($item->id);

foreach (@comments) {
    print $_->text, "\n  -- ", $_->author, "\n";
}

