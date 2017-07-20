#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use WWW::Wikipedia::LangTitles 'get_wiki_titles';
use Locale::Codes::Language;
binmode STDOUT, ":utf8";
my $article = 'King Kong';
my $titles = get_wiki_titles ($article);
for my $lang (keys %$titles) {
    my $l2c = code2language ($lang);
    if (! $l2c) {
	$l2c = $lang;
    }
    my $name = $titles->{$lang};
    if ($name ne $article) {
	print "$name in $l2c.\n";
    }
}
