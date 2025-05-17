use v5.14;
use warnings;

use Test::More;

use FindBin qw( $Bin );

use Test::MixedScripts qw( all_perl_files_scripts_ok );

all_perl_files_scripts_ok();

done_testing;
