use strict;
use Test2::V0;
use FindBin;

use WebService::YDMM;

my $dmm = WebService::YDMM->new(affiliate_id => "affiliate-990", api_id => "example");

subtest 'floor' => sub {

    subtest 'success' => sub {

        my $mock = mock 'HTTP::Tiny'  => (
            override => [
                get => sub { 
                            open my $fh, '<', "$FindBin::Bin/data/floor.json" or die "failed to open file: $!";
                            my $content = do { local $/; <$fh> };
                            return {success => 'true', content => "$content"};
                        }
            ],
        );

        subtest 'get_floor_data' => sub {
            ok (my $receive = $dmm->floor(), q{get_floor_data});
            ok (my $dmmcom = $receive->{site}->[0]);
            is ($dmmcom->{code}, q/DMM.com/);
            ok (my $AKB = $dmmcom->{service}->[0]);
            is ( $AKB->{name}, q/AKB48グループ/);
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

         subtest 'API acess failed' => sub {
            like ( dies { $dmm->floor() }, qr{FloorList API acess failed...},"API acess");
        };
    };
};

done_testing;