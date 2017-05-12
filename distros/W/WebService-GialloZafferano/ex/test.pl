#!/usr/bin/perl
use WebService::GialloZafferano;
use feature 'say';
my $Ricettario=WebService::GialloZafferano->new();
my @Ricette=$Ricettario->search("Spaghetti con le cozze");

say "Title : " .$_->title."\n\t".$_->text."\n\n" for (@Ricette);

