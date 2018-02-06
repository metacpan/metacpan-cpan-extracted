use strict;
use Test2::V0;
use FindBin;

use WebService::YDMM;

my $dmm = WebService::YDMM->new(affiliate_id => "Test_id-990", api_id => "Test-affiliate");

my @sites = qw/DMM.com DMM.R18/;

subtest 'item' => sub {

    subtest 'success' => sub {

        my $mock = mock 'HTTP::Tiny'  => (
            override => [
                get => sub { 
                            open my $fh, '<', "$FindBin::Bin/data/item.json" or die "failed to open file: $!";
                            my $content = do { local $/; <$fh> };
                            return {success => 'true', content => "$content"};
                        }
            ],
        );


        subtest 'in_site_name' => sub {
            for my $site (@sites) {
                ok(my $receive = $dmm->item(+{ site => $site , name => "test"}), q{in_site_name});
                is ($receive->{items}->[0]->{floor_name},"コミック");
                is ($receive->{items}->[0]->{iteminfo}->{author}->[1]->{name},"ハノカゲ");
            }
        };

        subtest 'out_site_name' => sub {
            for my $site (@sites) {
                ok (my $receive = $dmm->item( $site , {  name => "test"}), q{get_item_out});
                is ($receive->{items}->[0]->{floor_name},"コミック");
                is ($receive->{items}->[0]->{iteminfo}->{author}->[1]->{name},"ハノカゲ");
            } 
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

        subtest 'nothing site name' => sub {
            like( dies { $dmm->item(+{ name => "test" })}, qr{Require to Sitename for "DMM.com" or "DMM.R18"},q{ nothing_in});
        };

        subtest 'invalid site name' => sub {
            for my $damy_sites (qw/ DLL.com DLL.R18/){
                like( dies { $dmm->item(+{ site => $damy_sites, name => "test" })}, qr{Request to Site name for "DMM.com" or "DMM.R18"},"damy_$damy_sites");
            }
        };

        subtest 'API acess failed' => sub {
            for my $site (@sites) {
                like ( dies { $dmm->item(+{ site => $site, name => "name"}) }, qr{ItemList API acess failed...},"$site Item acess");
            }
        };
    };
};

done_testing;