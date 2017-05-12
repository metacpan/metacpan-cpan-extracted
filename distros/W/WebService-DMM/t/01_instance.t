use strict;
use warnings;
use Test::More;

use WebService::DMM;

subtest 'construct' => sub {
    my $dmm_min = WebService::DMM->new(
        affiliate_id => 'test-900',
        api_id       => 'test',
    );

    ok $dmm_min;
    isa_ok $dmm_min, 'WebService::DMM';

    my $dmm_max = WebService::DMM->new(
        affiliate_id => 'test-999',
        api_id       => 'test',
    );

    ok $dmm_max;
};

subtest 'invalid parameters' => sub {
    eval {
        my $dmm = WebService::DMM->new();
    };
    like $@, qr/missing mandatory parameter 'affiliate_id'/, 'no param';

    eval {
        my $dmm = WebService::DMM->new( affiliate_id => 'test' );
    };
    like $@, qr/missing mandatory parameter 'api_id'/, 'no api_id';

    eval {
        my $dmm = WebService::DMM->new( apid_id => 'test');
    };
    like $@, qr/missing mandatory parameter 'affiliate_id'/, 'no affiliate_id';

    eval {
        my $dmm = WebService::DMM->new(
            affiliate_id => 'test-899',
            api_id       => 'test'
        );
    };
    like $@, qr/Postfix of affiliate_id/, 'invalid affiliate_id under 900';

    eval {
        my $dmm = WebService::DMM->new(
            affiliate_id => 'test-1000',
            api_id       => 'test'
        );
    };
    like $@, qr/Postfix of affiliate_id/, 'invalid affiliate_id over 1000';
};

done_testing;
