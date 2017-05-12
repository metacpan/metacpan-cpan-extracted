#
# Test case for WebService::Recruit::CarSensor
#

use strict;
use Test::More tests => 16;


{
    use_ok('WebService::Recruit::CarSensor::Usedcar');
    my $obj = new WebService::Recruit::CarSensor::Usedcar();
    ok( ref $obj, 'new WebService::Recruit::CarSensor::Usedcar()');
}

{
    use_ok('WebService::Recruit::CarSensor::Catalog');
    my $obj = new WebService::Recruit::CarSensor::Catalog();
    ok( ref $obj, 'new WebService::Recruit::CarSensor::Catalog()');
}

{
    use_ok('WebService::Recruit::CarSensor::Brand');
    my $obj = new WebService::Recruit::CarSensor::Brand();
    ok( ref $obj, 'new WebService::Recruit::CarSensor::Brand()');
}

{
    use_ok('WebService::Recruit::CarSensor::Country');
    my $obj = new WebService::Recruit::CarSensor::Country();
    ok( ref $obj, 'new WebService::Recruit::CarSensor::Country()');
}

{
    use_ok('WebService::Recruit::CarSensor::LargeArea');
    my $obj = new WebService::Recruit::CarSensor::LargeArea();
    ok( ref $obj, 'new WebService::Recruit::CarSensor::LargeArea()');
}

{
    use_ok('WebService::Recruit::CarSensor::Pref');
    my $obj = new WebService::Recruit::CarSensor::Pref();
    ok( ref $obj, 'new WebService::Recruit::CarSensor::Pref()');
}

{
    use_ok('WebService::Recruit::CarSensor::Body');
    my $obj = new WebService::Recruit::CarSensor::Body();
    ok( ref $obj, 'new WebService::Recruit::CarSensor::Body()');
}

{
    use_ok('WebService::Recruit::CarSensor::Color');
    my $obj = new WebService::Recruit::CarSensor::Color();
    ok( ref $obj, 'new WebService::Recruit::CarSensor::Color()');
}


1;
