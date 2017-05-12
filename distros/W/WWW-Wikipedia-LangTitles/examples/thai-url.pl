#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use WWW::Wikipedia::LangTitles 'make_wiki_url';
print make_wiki_url ('ฮีเลียม', 'th'), "\n";
