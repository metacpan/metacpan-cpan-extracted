use strict;
use Test2::V0;
use FindBin;

use WebService::YDMM;

my $dmm = WebService::YDMM->new(affiliate_id => "affiliate-990", api_id => "example");

subtest 'actress' => sub {

    subtest 'success' => sub {

        my $mock = mock 'HTTP::Tiny'  => (
            override => [
                get => sub { 
                            open my $fh, '<', "$FindBin::Bin/data/actress.json" or die "failed to open file: $!";
                            my $content = do { local $/; <$fh> };
                            return {success => 'true', content => "$content"};
                        }
            ],
        );

        subtest 'get_actress_data' => sub {
            ok(my $receive = $dmm->actress({bust => 90, waist => "-60", sort => "-bust", hits => 10, keyword => "あさみ"}), q{get_actress_data});
            is ($receive->{actress}->[0]->{id},15365);
            is ($receive->{actress}->[1]->{imageURL}->{small},q[http://pics.dmm.co.jp/mono/actjpgs/thumbnail/hosikawa_asami.jpg])
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
           like ( dies { $dmm->actress(+{ name => "あさみ"} ) }, qr{ActressSearch API acess failed...},"API acess");
       };
   };
};

done_testing;