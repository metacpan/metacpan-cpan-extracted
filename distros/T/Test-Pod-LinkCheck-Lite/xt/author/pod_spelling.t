package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::Spelling;
	1;
    } or do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
    Test::Spelling->import();
}

add_stopwords (<DATA>);

all_pod_files_spelling_ok ();

1;
__DATA__
Alceu
Andreas
Anwar
de
deponent
Freitas
hocery
Kirmess
König
Mohammed
merchantability
recursed
ReactOS
Rezić
Rodrigues
sayeth
Slaven
Wyant
