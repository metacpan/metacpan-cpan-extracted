#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use lib '/home/ben/projects/www-wikipedia-langtitles/lib';
use WWW::Wikipedia::LangTitles 'get_wiki_titles';
use Chemistry::Elements;
binmode STDOUT, ":utf8";
my %n = %Chemistry::Elements::names;
for my $k (sort {$a <=> $b} keys %n) {
my $e = $n{$k}[1];
print "$e ";
exit;
my $map = get_wiki_titles ($e);
print $map->{ja}, "\n";
#for my $j (keys %$map) {
#print "$j = $map->{$j}\n";
#}
#exit;
sleep (2);
}
