#
# Test case for WebService::Recruit::AbRoad
#

use strict;
use Test::More tests => 18;


{
    use_ok('WebService::Recruit::AbRoad::Tour');
    my $obj = new WebService::Recruit::AbRoad::Tour();
    ok( ref $obj, 'new WebService::Recruit::AbRoad::Tour()');
}

{
    use_ok('WebService::Recruit::AbRoad::Area');
    my $obj = new WebService::Recruit::AbRoad::Area();
    ok( ref $obj, 'new WebService::Recruit::AbRoad::Area()');
}

{
    use_ok('WebService::Recruit::AbRoad::Country');
    my $obj = new WebService::Recruit::AbRoad::Country();
    ok( ref $obj, 'new WebService::Recruit::AbRoad::Country()');
}

{
    use_ok('WebService::Recruit::AbRoad::City');
    my $obj = new WebService::Recruit::AbRoad::City();
    ok( ref $obj, 'new WebService::Recruit::AbRoad::City()');
}

{
    use_ok('WebService::Recruit::AbRoad::Hotel');
    my $obj = new WebService::Recruit::AbRoad::Hotel();
    ok( ref $obj, 'new WebService::Recruit::AbRoad::Hotel()');
}

{
    use_ok('WebService::Recruit::AbRoad::Airline');
    my $obj = new WebService::Recruit::AbRoad::Airline();
    ok( ref $obj, 'new WebService::Recruit::AbRoad::Airline()');
}

{
    use_ok('WebService::Recruit::AbRoad::Kodawari');
    my $obj = new WebService::Recruit::AbRoad::Kodawari();
    ok( ref $obj, 'new WebService::Recruit::AbRoad::Kodawari()');
}

{
    use_ok('WebService::Recruit::AbRoad::Spot');
    my $obj = new WebService::Recruit::AbRoad::Spot();
    ok( ref $obj, 'new WebService::Recruit::AbRoad::Spot()');
}

{
    use_ok('WebService::Recruit::AbRoad::TourTally');
    my $obj = new WebService::Recruit::AbRoad::TourTally();
    ok( ref $obj, 'new WebService::Recruit::AbRoad::TourTally()');
}


1;
