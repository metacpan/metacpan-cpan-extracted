use strict;
use Test2::V0;

use WebService::YDMM;

subtest 'new -- make_instance' =>  sub {

    subtest 'success' => sub {
        ok(WebService::YDMM->new(affiliate_id => "Test_id-990", api_id => "Test-affiliate"), q{ sucess });
    };

    subtest 'error'   => sub {
        subtest 'not_input' => sub {
            like( dies {WebService::YDMM->new()}, qr{affiliate_id is required}, 'all requires params nothing input');
            like( dies {WebService::YDMM->new( api_id => "api_id")}, qr{affiliate_id is required}, 'affiliate_id not input');
            like( dies {WebService::YDMM->new( affiliate_id=> "Test_id-990")}, qr{api_id is required}, 'api_id not input');
        };

        subtest 'invalid'   => sub {
            my $cases = { not_three_digit => 99, 'not_990-999' => 989, over_999 => 1000, froat_number => 990.5 };

            for my $case (keys %$cases){
                like( dies {WebService::YDMM->new(affiliate_id => "Test_id-$cases->{$case}", api_id => "Test-affiliate")}, qr{Postfix of affiliate_id is '990--999'},qw{ $case });
            }
        };
    };

};

done_testing;
