#
# Test case for WebService::Recruit::Eyeco
#

use strict;
use Test::More tests => 6;


{
    use_ok('WebService::Recruit::Eyeco::Item');
    my $obj = new WebService::Recruit::Eyeco::Item();
    ok( ref $obj, 'new WebService::Recruit::Eyeco::Item()');
}

{
    use_ok('WebService::Recruit::Eyeco::LargeCategory');
    my $obj = new WebService::Recruit::Eyeco::LargeCategory();
    ok( ref $obj, 'new WebService::Recruit::Eyeco::LargeCategory()');
}

{
    use_ok('WebService::Recruit::Eyeco::SmallCategory');
    my $obj = new WebService::Recruit::Eyeco::SmallCategory();
    ok( ref $obj, 'new WebService::Recruit::Eyeco::SmallCategory()');
}


1;
