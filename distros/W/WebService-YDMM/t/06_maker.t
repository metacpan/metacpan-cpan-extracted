use strict;
use Test2::V0;
use FindBin;

use WebService::YDMM;

my $dmm = WebService::YDMM->new(affiliate_id => "Test_id-990", api_id => "Test-affiliate");

subtest 'maker' => sub {

    subtest 'success' => sub {

        my $mock = mock 'HTTP::Tiny'  => (
            override => [
                get => sub { 
                            open my $fh, '<', "$FindBin::Bin/data/maker.json" or die "failed to open file: $!";
                            my $content = do { local $/; <$fh> };
                            return {success => 'true', content => "$content"};
                        }
            ],
        );


        subtest 'in_floor_id' => sub {
            ok(my $receive = $dmm->maker(+{ floor_id => 43  }), q{in_floor_id});
            is ($receive->{maker}->[0]->{maker_id},1157);
            is ($receive->{site_code},"DMM.R18");
        };

        subtest 'out_floor_id' => sub {
            ok(my $receive = $dmm->maker(43,+{}), q{out_floor_id});
            is ($receive->{maker}->[1]->{ruby},q/とりう゛ぃあるりすく/);
            is ($receive->{service_code},"digital");
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
            like( dies { $dmm->maker(+{ name => "test" })}, qr{Require to floor_id},q{ nothing_in});
            like( dies { $dmm->maker( undef,+{ name => "test" })}, qr{Require to floor_id},q{ nothing_in});
        };

        subtest 'API acess failed' => sub {
            like ( dies { $dmm->maker(+{ floor_id => 10} ) }, qr{MakerSearch API acess failed...},"API acess");
        };
    };
};

done_testing;