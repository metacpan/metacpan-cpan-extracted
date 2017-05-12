#!/usr/bin/perl

use WWW::BurrpTV;

my $tv = WWW::BurrpTV->new;
my $channel = join ' ',@ARGV or die "Usage: ./test.pl \"Star Movies\"\n";
my $show = ${$tv->get_shows(channel => $channel)}[0];
print uc $show->{_show};
