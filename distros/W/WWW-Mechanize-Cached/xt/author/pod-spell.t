use strict;
use warnings;
use Test::More;

# generated by Dist::Zilla::Plugin::Test::PodSpelling 2.007005
use Test::Spelling 0.12;
use Pod::Wordlist;


add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw( bin lib ) );
__DATA__
2004
2009
Alders
Alders'
Anderson
Andy
Bjorn
Book
Bowers
Cached
Champoux
Choroba
Dan
Fredric
Gardner
Iain
John
Jonathan
July
Kent
Lester
Mark
Mech
Mechanize
Neil
Olaf
Rubin
SJ
Strand
Truskett
WWW
Yanick
and
author
bolav
choroba
current
genehack
grinnz
jjr
kentfredric
lib
maintainer
maintainership
mjg
neil
olaf
original
params
petdance
simbabque
yanick
