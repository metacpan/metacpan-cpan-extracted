#! /usr/bin/perl -I../lib

use WWW::VieDeMerde;

my $vdm = WWW::VieDeMerde->new();

my @last;

for (qw/amour argent travail sante sexe inclassable/) {
		@last = $vdm->cat($_);
		print $_, "\n";
		print $last[0]->texte, "\n\n";
}

