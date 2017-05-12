use strict;
use Test::More;
use Test::EOF;
use Cwd;

all_perl_files_ok('lib');
all_perl_files_ok('t/basic.t', { minimum_newlines => $^O eq 'MSWin32' ? 1 : 3 });
done_testing;





