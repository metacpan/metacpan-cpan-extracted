#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Test::More;
use Unicode::Diacritic::Strip 'strip_diacritics';
use utf8;
my $viet = 'Phổ điện';
my $stripped = 'Pho đien';
binmode STDOUT, ":utf8";
my ($out, $list) = strip_diacritics ($viet, verbose => 0);
is ($out, $stripped, "Stripped the same as expected");
done_testing ();
