use strict;
use Test::More;

# Test a basic use statement
BEGIN {
    use_ok('VMware::vCloud');
    use_ok('VMware::vCloud::vApp');
    use_ok('VMware::API::vCloud');
}

done_testing;
