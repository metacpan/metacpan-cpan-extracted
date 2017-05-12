use strict;
use warnings;
use Test::More;
use Test::Spelling;
use Pod::Wordlist;

add_stopwords( <DATA> );
all_pod_files_spelling_ok();

__DATA__
AnnoCPAN
CPAN
perlmonks
RSS
Boumans
Cees
Godin
Harkins
Hek
Purkis
Schleicher
Muhlestein
Perrin
Prew
Krieger
LICENCE
McCann
Jos
Jost
qa
Adrian
Cantrell
Janek
Jore
ben
Khemir
Nadim
Pagaltzis
Dolan
RT
Ricardo
Signes
Rabbitson
Schwern
Tulloh
