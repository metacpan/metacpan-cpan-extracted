#
# Test case for WebService::Recruit::AkasuguUchiiwai
#

use strict;
use Test::More tests => 8;


{
    use_ok('WebService::Recruit::AkasuguUchiiwai::Item');
    my $obj = new WebService::Recruit::AkasuguUchiiwai::Item();
    ok( ref $obj, 'new WebService::Recruit::AkasuguUchiiwai::Item()');
}

{
    use_ok('WebService::Recruit::AkasuguUchiiwai::Category');
    my $obj = new WebService::Recruit::AkasuguUchiiwai::Category();
    ok( ref $obj, 'new WebService::Recruit::AkasuguUchiiwai::Category()');
}

{
    use_ok('WebService::Recruit::AkasuguUchiiwai::Target');
    my $obj = new WebService::Recruit::AkasuguUchiiwai::Target();
    ok( ref $obj, 'new WebService::Recruit::AkasuguUchiiwai::Target()');
}

{
    use_ok('WebService::Recruit::AkasuguUchiiwai::Feature');
    my $obj = new WebService::Recruit::AkasuguUchiiwai::Feature();
    ok( ref $obj, 'new WebService::Recruit::AkasuguUchiiwai::Feature()');
}


1;
