use strict;
use Test2::V0;
use FindBin;

use WebService::YDMM;

my $dmm = WebService::YDMM->new(affiliate_id => "Test_id-990", api_id => "Test-affiliate");

subtest 'series' => sub {

    subtest 'success' => sub {

        my $mock = mock 'HTTP::Tiny'  => (
            override => [
                get => sub { 
                            open my $fh, '<', "$FindBin::Bin/data/series.json" or die "failed to open file: $!";
                            my $content = do { local $/; <$fh> };
                            return {success => 'true', content => "$content"};
                        }
            ],
        );


        subtest 'in_floor_id' => sub {
            ok(my $receive = $dmm->series(+{ floor_id => 27 }), q{in_floor_id});
            is ($receive->{series}->[0]->{series_id},11773);
            is ($receive->{floor_code},"book");
        };

        subtest 'out_floor_id' => sub {
            ok(my $receive = $dmm->series(27,+{}), q{out_floor_id});
            is ($receive->{series}->[9]->{series_id},50716);
            is ($receive->{series}->[9]->{name},q/オーバーマン キングゲイナー/);
        };
    };

    subtest 'error' => sub {

        my $mock = mock 'HTTP::Tiny'  => (
            override => [
                get => sub { 
                            return {success => undef, content => undef };
                        }
            ],
        );

        subtest 'nothing floor_id ' => sub {
            like( dies { $dmm->series(+{ name => "test" })}, qr{Require to floor_id},q{ nothing_in});
            like( dies { $dmm->series( undef,+{ name => "test" })}, qr{Require to floor_id},q{ nothing_in});
        };

        subtest 'API acess failed' => sub {
            like ( dies { $dmm->series(+{ floor_id => 10} ) }, qr{SeriesSearch API acess failed...},"API acess");
        };
    };
};

done_testing;