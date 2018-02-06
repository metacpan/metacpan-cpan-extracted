use strict;
use Test2::V0;
use FindBin;

use WebService::YDMM;

my $dmm = WebService::YDMM->new(affiliate_id => "Test_id-990", api_id => "Test-affiliate");

subtest 'genre' => sub {

    subtest 'success' => sub {

        my $mock = mock 'HTTP::Tiny'  => (
            override => [
                get => sub { 
                            open my $fh, '<', "$FindBin::Bin/data/genre.json" or die "failed to open file: $!";
                            my $content = do { local $/; <$fh> };
                            return {success => 'true', content => "$content"};
                        }
            ],
        );


        subtest 'in_floor_id' => sub {
            ok(my $receive = $dmm->genre(+{ floor_id => 25 , initial => "き"}), q{in_floor_id});
            is ($receive->{genre}->[0]->{genre_id},73115);
            is ($receive->{service_code},"mono");
        };

        subtest 'out_floor_id' => sub {
            ok(my $receive = $dmm->genre(25,+{ initial => "き"}), q{out_floor_id});
            is ($receive->{genre}->[1]->{genre_id},73117);
            is ($receive->{floor_code},"dvd");
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
            like( dies { $dmm->genre(+{ name => "test" })}, qr{Require to floor_id},q{ nothing_in});
            like( dies { $dmm->genre( undef,+{ name => "test" })}, qr{Require to floor_id},q{ nothing_in});
        };

        subtest 'API acess failed' => sub {
            like ( dies { $dmm->genre(+{ floor_id => 10} ) }, qr{GenreSearch API acess failed...},"API acess");
        };
    };
};

done_testing;