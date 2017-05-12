#
# Test case for WebService::Recruit::Akasugu
#

use strict;
use Test::More tests => 10;


{
    use_ok('WebService::Recruit::Akasugu::Item');
    my $obj = new WebService::Recruit::Akasugu::Item();
    ok( ref $obj, 'new WebService::Recruit::Akasugu::Item()');
}

{
    use_ok('WebService::Recruit::Akasugu::LargeCategory');
    my $obj = new WebService::Recruit::Akasugu::LargeCategory();
    ok( ref $obj, 'new WebService::Recruit::Akasugu::LargeCategory()');
}

{
    use_ok('WebService::Recruit::Akasugu::MiddleCategory');
    my $obj = new WebService::Recruit::Akasugu::MiddleCategory();
    ok( ref $obj, 'new WebService::Recruit::Akasugu::MiddleCategory()');
}

{
    use_ok('WebService::Recruit::Akasugu::SmallCategory');
    my $obj = new WebService::Recruit::Akasugu::SmallCategory();
    ok( ref $obj, 'new WebService::Recruit::Akasugu::SmallCategory()');
}

{
    use_ok('WebService::Recruit::Akasugu::Age');
    my $obj = new WebService::Recruit::Akasugu::Age();
    ok( ref $obj, 'new WebService::Recruit::Akasugu::Age()');
}


1;
