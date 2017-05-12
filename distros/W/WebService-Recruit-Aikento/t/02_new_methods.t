#
# Test case for WebService::Recruit::Aikento
#

use strict;
use Test::More tests => 6;


{
    use_ok('WebService::Recruit::Aikento::Item');
    my $obj = new WebService::Recruit::Aikento::Item();
    ok( ref $obj, 'new WebService::Recruit::Aikento::Item()');
}

{
    use_ok('WebService::Recruit::Aikento::LargeCategory');
    my $obj = new WebService::Recruit::Aikento::LargeCategory();
    ok( ref $obj, 'new WebService::Recruit::Aikento::LargeCategory()');
}

{
    use_ok('WebService::Recruit::Aikento::SmallCategory');
    my $obj = new WebService::Recruit::Aikento::SmallCategory();
    ok( ref $obj, 'new WebService::Recruit::Aikento::SmallCategory()');
}


1;
