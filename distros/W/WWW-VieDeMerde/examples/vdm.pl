#! /usr/bin/perl -I../lib

use WWW::VieDeMerde;

my $vdm = WWW::VieDeMerde->new();
my $id = shift;

my $item;
if ($id) {
    $item = $vdm->get($id);
}
else {
   $item = $vdm->random();
}
die unless defined($item);
print $item->text, "\n";
print $item->id, "\n";

