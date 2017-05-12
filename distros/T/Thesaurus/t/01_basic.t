use strict;

use File::Spec;

use lib File::Spec->curdir, File::Spec->catdir( File::Spec->curdir, 't' );

use SharedTests;

SharedTests::run_tests( class => 'Thesaurus' );
