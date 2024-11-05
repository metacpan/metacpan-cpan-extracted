use Test2::Tools::Exception qw/dies lives/;
use Test2::V0;

use Weather::API::Base ':all';

subtest 'Constructor' => sub {
    like(dies {my $base = Weather::API::Base->new(scheme=>'ftp')}, qr/scheme/, "Wrong scheme");
};

subtest '_verify_lat_lon' => sub {
    like(dies {Weather::API::Base::_verify_lat_lon()}, qr/lat between/, "Latitude missing");
    like(dies {Weather::API::Base::_verify_lat_lon({lat=>50})}, qr/lon between/, "Longitude missing");
    like(dies {Weather::API::Base::_verify_lat_lon({lat=>100})}, qr/lat between/, "Latitude wrong");
    like(dies {Weather::API::Base::_verify_lat_lon({lat=>50, lon=>200})}, qr/lon between/, "Longitude wrong");
    ok(lives {Weather::API::Base::_verify_lat_lon({lat=>50, lon=>100})}, "Lat/lon ok");
};

subtest '_deref' => sub {
    like(dies {Weather::API::Base::_deref()}, qr/Could not decode/, "No param");
};

subtest 'convert_units' => sub {
    like(dies {convert_units()}, qr/Value not defined/, "Missing val");
    like(dies {convert_units('x', 'km', 1)}, qr/not recognized/, "Unknown units");
    like(dies {convert_units('km', 'km/h', 1)}, qr/Cannot convert/, "Incompatible units");
};

subtest 'datetime_to_ts' => sub {
    like(dies {datetime_to_ts('20243108')}, qr/Unrecognized date format/, "Wrong date");
};

subtest '_get_output' => sub {
    my $base = Weather::API::Base->new(error => 'die');
    my $resp = HTTP::Response->new(401, 'Unauthorized', undef, '{}');
    like(dies {$base->_get_output($resp)}, qr/401 Unauthorized/, "Dies with 401");
};


done_testing;
