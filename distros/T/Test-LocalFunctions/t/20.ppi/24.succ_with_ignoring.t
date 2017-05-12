#!perl

use strict;
use warnings;
use utf8;
use FindBin;
push @INC, "$FindBin::Bin/../resource/lib";

use Test::LocalFunctions::PPI;

use Test::More;

require "Test/LocalFunctions/Succ_with_ignore.pm";
local_functions_ok( "t/resource/lib/Test/LocalFunctions/Succ_with_ignore.pm", { ignore_functions => [ '_bar', '_baz', '\A_foobar' ] } );

done_testing;
