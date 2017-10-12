#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use WWW::WWWJDIC;
my $wj = WWW::WWWJDIC->new (mirror => 'usa');
print $wj->lookup_url ('日本'), "\n";
