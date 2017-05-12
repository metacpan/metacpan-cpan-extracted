#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use WWW::Wikipedia::LangTitles 'get_wiki_titles';
binmode STDOUT, ":encoding(utf8)";
my $title = 'Three-phase electric power';
my $links = get_wiki_titles ($title);
print "$title is '$links->{de}' in German.\n";
my $film = '東京物語';
my $flinks = get_wiki_titles ($film, lang => 'ja');
print "映画「$film」はイタリア語で'$flinks->{it}'と名付けた。\n";

