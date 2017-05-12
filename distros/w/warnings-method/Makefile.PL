use 5.008_001;

use strict;
use warnings;
use inc::Module::Install;

if(eval{ require warnings::method && warnings::method->VERSION < 0.10 }){
	warn <<'END';
********* IMCOMPATIBLE CHANGE *********

The API of warnings::method  has changed in 0.10.

(1) The "method" warnings category has been removed.
    Use the "syntax" category instead.

(2) The "use warnings::method" directive only installs the check routine.
    To enable this routine, use the warnings pragma.

END
}

name 'warnings-method';

all_from 'method.pm';

WriteMakefile(
	clean => {FILES => 'warnings-method-* cover_db *.gcov *.gcda *.gcno *.stackdump'},
);
