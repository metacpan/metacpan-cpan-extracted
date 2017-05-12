#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use Test::More;
push @INC, "$FindBin::Bin/resource/lib";

use Test::LocalFunctions;

chdir "$FindBin::Bin/resource";
$ExtUtils::Manifest::MANIFEST = "$FindBin::Bin/resource/MANIFEST";

$ENV{TEST_LOCALFUNCTIONS_TEST_PHASE} = 1;
all_local_functions_ok(
    {
        ignore_modules => [
            'lib/Test/LocalFunctions/Fail1.pm',
            'Test/LocalFunctions/Fail2.pm',
            'Test::LocalFunctions::Fail3'
        ]
    }
);

done_testing;
