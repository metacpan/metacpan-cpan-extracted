package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::Spelling;
	Test::Spelling->import();
	1;
    } or do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
}

add_stopwords (<DATA>);

all_pod_files_spelling_ok ();

1;
__DATA__
Aldo
Calpini
GetFileTime
Jenda
Krynicky
MSWin
McQueen
Nemours
PPM
SetFileTime
Tye
Wyant
cc
de
dll
exportable
filename
merchantability
orthogonality's
readonly
stat
tuits
