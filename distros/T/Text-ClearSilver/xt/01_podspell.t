#!perl -w

use strict;
use Test::More;

eval q{ use Test::Spelling };

plan skip_all => q{Test::Spelling is not installed.}
	if $@;

add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');

__DATA__
Text::ClearSilver
goro
gfx
Craftworks
Neotonic
cpan
TCS
HDF
CS
filename
runtime
hierarchial
dataset
JavaScript
TODO
html
