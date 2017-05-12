#
# Test case for WebService::Recruit::FromA
#

use strict;
use Test::More tests => 2;


{
    use_ok('WebService::Recruit::FromA::JobSearch');
    my $obj = new WebService::Recruit::FromA::JobSearch();
    ok( ref $obj, 'new WebService::Recruit::FromA::JobSearch()');
}


1;
