#!perl -w

use strict;
use Test::More;

eval q{ use Test::Spellunker};

plan skip_all => q{Test::Spellunker is not installed.}
	if $@;

add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');

__DATA__
Goro Fuji
gfuji(at)cpan.org
Test::LeakTrace
