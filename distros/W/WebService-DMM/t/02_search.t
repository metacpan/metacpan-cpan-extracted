use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw/mock_guard/;

use WebService::DMM;

subtest 'search' => sub {
    my $dmm = WebService::DMM->new(
        affiliate_id => 'test-950',
        api_id       => 'test',
    );

    can_ok $dmm, 'search';
};

subtest 'invalid parameter' => sub {
    my $dmm = WebService::DMM->new(
        affiliate_id => 'test-988',
        api_id       => 'test',
    );

    eval {
        $dmm->search();
    };
    like $@, qr/'site' parameter is mandatory/, 'undefined site parameter';

    eval {
        $dmm->search( site => 'DMM.org' );
    };
    like $@, qr/'DMM\.co\.jp' or 'DMM\.com'/, 'invalid site parameter';

    eval {
        $dmm->search( site => 'DMM.co.jp', hits => 101 );
    };
    like $@, qr/should be 1 <= n <= 100/, 'invalid hits parameter';

    eval {
        $dmm->search( site => 'DMM.com', offset => -1 );
    };
    like $@, qr/should be positive number/, 'invalid offset parameter';

    eval {
        $dmm->search( site => 'DMM.com', version => '0' );
    };
    like $@, qr/Invalid version '0'/, 'invalid version number';
};

subtest 'service and floor at DMM.com' => sub {
    my $guard = mock_guard('WebService::DMM', +{
        _send_request => sub { 1 },
    });

    my $dmm = WebService::DMM->new(
        affiliate_id => 'test-988',
        api_id       => 'test',
    );

    my %service_floor = (
        lod => [qw/akb48 ske48/],
        digital => [qw/bandai anime video idol cinema fight/],
        monthly => [qw/toei animate shochikugeino idol cinepara dgc fleague/],
        digital_book => [qw/comic novel photo otherbooks/],
        pcsoft => [qw/pcgame pcsoft/],
        mono => [qw/dvd cd book game hobby kaden houseware gourmet/],
        rental => [qw/rental_dvd ppr_dvd rental_cd ppr_cd comic/],
        nandemo => [qw/fashion_ladies fashion_mems rental_iroiro/],
    );

    for my $service (keys %service_floor) {
        for my $floor ( @{$service_floor{$service}} ) {
            ok $dmm->search(
                site    => 'DMM.com',
                service => $service,
                floor   => $floor,
            ), "search ${service}:${floor} at DMM.com";
        }
    }
};

subtest 'service and floor at DMM.co.jp' => sub {
    my $guard = mock_guard('WebService::DMM', +{
        _send_request => sub { 1 },
    });

    my $dmm = WebService::DMM->new(
        affiliate_id => 'test-988',
        api_id       => 'test',
    );

    my %service_floor = (
        digital => [qw/videoa videoc nikkatsu anime photo/],
        monthly => [qw/shirouto nikkatsu paradisetv animech dream
                       avstation playgirl alice crystal hmp
                       waap momotarobb moodyz prestige jukujo
                       sod mania s1 kmp mousouzoku/],
        ppm => [qw/video videoc/],
        pcgame => [qw/pcgame/],
        doujin => [qw/doujin/],
        book => [qw/book/],
        mono => [qw/dvd goods anime pcgame book doujin/],
        rental => [qw/rental_dvd ppr_dvd/],
    );

    for my $service (keys %service_floor) {
        for my $floor ( @{$service_floor{$service}} ) {
            ok $dmm->search(
                site    => 'DMM.co.jp',
                service => $service,
                floor   => $floor,
            ), "search ${service}:${floor} at DMM.co.jp";
        }
    }
};

done_testing;
