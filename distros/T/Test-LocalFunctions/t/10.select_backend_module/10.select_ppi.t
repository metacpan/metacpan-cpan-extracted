#!perl

use strict;
use warnings;
use FindBin;

use Test::More;

BEGIN {
    unshift @INC, "$FindBin::Bin/lib";
}

subtest 'Environment variable of "T_LF_PPI" is enabled' => sub {
    $ENV{T_LF_PPI} = 1;
    require Test::LocalFunctions;
    ok $INC{'Test/LocalFunctions/PPI.pm'};
    ok not $INC{'Test/LocalFunctions/Fast.pm'};
    is Test::LocalFunctions::which_backend_is_used(), 'Test::LocalFunctions::PPI';

    $ENV{T_LF_PPI} = undef;
    delete $INC{'Test/LocalFunctions.pm'};
    delete $INC{'Test/LocalFunctions/PPI.pm'};
};

subtest 'Should select Test::LocalFunctions::PPI' => sub {
    require Test::LocalFunctions;

    ok $INC{'Test/LocalFunctions/PPI.pm'};
    ok not $INC{'Test/LocalFunctions/Fast.pm'};
    is Test::LocalFunctions::which_backend_is_used(), 'Test::LocalFunctions::PPI';

    delete $INC{'Test/LocalFunctions.pm'};
    delete $INC{'Test/LocalFunctions/PPI.pm'};
};
done_testing;
