#
# Test case for WebService::Recruit::HotPepperBeauty
#

use strict;
use Test::More tests => 18;


{
    use_ok('WebService::Recruit::HotPepperBeauty::Salon');
    my $obj = new WebService::Recruit::HotPepperBeauty::Salon();
    ok( ref $obj, 'new WebService::Recruit::HotPepperBeauty::Salon()');
}

{
    use_ok('WebService::Recruit::HotPepperBeauty::ServiceArea');
    my $obj = new WebService::Recruit::HotPepperBeauty::ServiceArea();
    ok( ref $obj, 'new WebService::Recruit::HotPepperBeauty::ServiceArea()');
}

{
    use_ok('WebService::Recruit::HotPepperBeauty::MiddleArea');
    my $obj = new WebService::Recruit::HotPepperBeauty::MiddleArea();
    ok( ref $obj, 'new WebService::Recruit::HotPepperBeauty::MiddleArea()');
}

{
    use_ok('WebService::Recruit::HotPepperBeauty::SmallArea');
    my $obj = new WebService::Recruit::HotPepperBeauty::SmallArea();
    ok( ref $obj, 'new WebService::Recruit::HotPepperBeauty::SmallArea()');
}

{
    use_ok('WebService::Recruit::HotPepperBeauty::HairImage');
    my $obj = new WebService::Recruit::HotPepperBeauty::HairImage();
    ok( ref $obj, 'new WebService::Recruit::HotPepperBeauty::HairImage()');
}

{
    use_ok('WebService::Recruit::HotPepperBeauty::HairLength');
    my $obj = new WebService::Recruit::HotPepperBeauty::HairLength();
    ok( ref $obj, 'new WebService::Recruit::HotPepperBeauty::HairLength()');
}

{
    use_ok('WebService::Recruit::HotPepperBeauty::Kodawari');
    my $obj = new WebService::Recruit::HotPepperBeauty::Kodawari();
    ok( ref $obj, 'new WebService::Recruit::HotPepperBeauty::Kodawari()');
}

{
    use_ok('WebService::Recruit::HotPepperBeauty::KodawariSetsubi');
    my $obj = new WebService::Recruit::HotPepperBeauty::KodawariSetsubi();
    ok( ref $obj, 'new WebService::Recruit::HotPepperBeauty::KodawariSetsubi()');
}

{
    use_ok('WebService::Recruit::HotPepperBeauty::KodawariMenu');
    my $obj = new WebService::Recruit::HotPepperBeauty::KodawariMenu();
    ok( ref $obj, 'new WebService::Recruit::HotPepperBeauty::KodawariMenu()');
}


1;
