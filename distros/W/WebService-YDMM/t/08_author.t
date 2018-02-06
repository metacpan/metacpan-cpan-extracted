use strict;
use Test2::V0;
use FindBin;

use WebService::YDMM;

my $dmm = WebService::YDMM->new(affiliate_id => "Test_id-990", api_id => "Test-affiliate");

subtest 'author' => sub {

    subtest 'success' => sub {

        my $mock = mock 'HTTP::Tiny'  => (
            override => [
                get => sub { 
                            open my $fh, '<', "$FindBin::Bin/data/author.json" or die "failed to open file: $!";
                            my $content = do { local $/; <$fh> };
                            return {success => 'true', content => "$content"};
                        }
            ],
        );


        subtest 'in_floor_id' => sub {
            ok(my $receive = $dmm->author(+{ floor_id => 10 }), q{in_floor_id});
            is ($receive->{author}->[0]->{author_id},243066);
            is ($receive->{site_code},"DMM.com");
        };

        subtest 'out_floor_id' => sub {
            ok(my $receive = $dmm->author(10,+{}), q{out_floor_id});
            is ($receive->{author}->[0]->{author_id},243066);
            is ($receive->{site_code},"DMM.com");
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
            like( dies { $dmm->author(+{ name => "test" })}, qr{Require to floor_id},q{ nothing_in});
            like( dies { $dmm->author( undef,+{ name => "test" })}, qr{Require to floor_id},q{ nothing_in});
        };

        subtest 'API acess failed' => sub {
            like ( dies { $dmm->author(+{ floor_id => 10} ) }, qr{AuthorSearch API acess failed...},"API acess");
        };
    };
};

done_testing;