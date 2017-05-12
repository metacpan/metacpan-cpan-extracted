use strict;
use warnings;

# Check that our own source is clean
use Test::EOL;
use Cwd;
use File::Spec;
all_perl_files_ok(File::Spec->catdir(cwd(), 'lib'), { trailing_whitespace => 1 });

