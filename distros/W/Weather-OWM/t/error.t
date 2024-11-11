use Test2::Tools::Exception qw/dies lives/;
use Test2::V0;

use HTTP::Response;
use LWP::UserAgent;
use Weather::OWM;

subtest 'Constructor' => sub {
    like(dies {my $owm = Weather::OWM->new()}, qr/key required/, "No API key");
    like(dies {my $owm = Weather::OWM->new(key=>'MYKEY',scheme=>'ftp')}, qr/scheme/, "Wrong scheme");
};

subtest 'one_call' => sub {
    my $owm = Weather::OWM->new(key=>'MYKEY');
    like(dies {$owm->one_call(product=>'forecast')}, qr/lat & lon/, "No coordinates");
    like(dies {$owm->one_call(lat=>50)}, qr/both lat & lon/, "Latitude wrong");
    like(dies {$owm->one_call(lat=>200,lon=>0)}, qr/lat between/, "Latitude wrong");
    like(dies {$owm->one_call(lon=>200,lat=>0)}, qr/lon between/, "Longitude wrong");
    like(dies {$owm->one_call(product=>'a')}, qr/product has to be/, "Wrong product");
    my $mock = Test2::Mock->new(
        class    => 'LWP::UserAgent',
        override => [
            get => sub {
                return HTTP::Response->new(200, 'SUCCESS', undef, '[{"lon":"-70.25","lat":"43.66"}]');
            },
        ],
    );
    like(dies {$owm->one_call(product=>'daily',zip=>10001)}, qr/date expected/, "No date");
    like(dies {$owm->one_call(product=>'daily',city=>'a', date=>1)}, qr/1979-01-02/, "Invalid date");
    like(dies {$owm->one_call(product=>'daily',city=>'a', date=>"15-07-99")}, qr/date expected in the format/, "Invalid date format");
    like(dies {$owm->one_call(product=>'historical',city=>'a', date=>1)}, qr/1979-01-01/, "Invalid date");
    like(dies {$owm->one_call(product=>'historical',city=>'a', date=>"15-07-99")}, qr/date format/, "Invalid date format");
};

subtest 'get_geo' => sub {
    my $owm = Weather::OWM->new(key=>'MYKEY');
    like(dies {$owm->geo(lat=>0)}, qr/both lat & lon/, "geo croak");
};


subtest 'get_weather' => sub {
    my $owm = Weather::OWM->new(key=>'MYKEY');
    like(dies {$owm->get_weather(product=>'a',lat=>0,lon=>0)}, qr/valid prod/, "Invalid product");
};

subtest 'get_history' => sub {
    my $owm = Weather::OWM->new(key=>'MYKEY');
    like(dies {$owm->get_history(product=>'a',lat=>0,lon=>0)}, qr/valid prod/, "Invalid product");
    like(dies {$owm->get_history(product=>'day',lat=>0,lon=>0)}, qr/month is expected/, "Expected month");
    like(dies {$owm->get_history(lat=>0,lon=>0,start=>1)}, qr/end or cnt/, "Expected end or cnt");
};

subtest 'request errors' => sub {
    my $owm  = Weather::OWM->new(key=>'MYKEY', error=>'die');
    my $mock = Test2::Mock->new(
        class => 'LWP::UserAgent',
        override => [
            get => sub { return HTTP::Response->new(401, 'Unauthorized', undef, '{}') },
        ],
    );
    like(dies {$owm->get_history(city_id=>1,start=>1586853378,end=>1586853379,product=>'precip')}, qr/401 Unauth/, "401 error");
    $mock = undef;
    $mock = Test2::Mock->new(
        class => 'LWP::UserAgent',
        override => [
            get => sub { return HTTP::Response->new(200, 'SUCCESS', undef, "") },
        ],
    );
    like(dies {my %re = $owm->get_history(zip=>10001,start=>1586853378,end=>1586853379,product=>'temp',error=>'return')}, qr//, "JSON error");
};

done_testing;
