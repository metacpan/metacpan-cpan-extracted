use v5.14;
use warnings;

use Test::More;

use FindBin qw( $Bin );

use Test::MixedScripts qw( file_scripts_ok );

file_scripts_ok( "${Bin}/../lib/Test/MixedScripts.pm", { scripts => [qw( Common Latin )] } );

done_testing;
