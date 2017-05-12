use strict;
use Test::More;
use WebService::DMM;
use utf8;
eval q{
    use Config::Pit;
};
plan skip_all => "Config::Pit is not installed." if $@;

my $config = pit_get('dmm.co.jp', require => {
    affiliate_id => 'DMM Affiliate ID',
    api_id       => 'DMM API ID',
});
plan skip_all => "DMM config not found" unless $config->{api_id};

my $dmm = WebService::DMM->new(
    affiliate_id => 'maybenotfound-999',
    api_id       => $config->{api_id},
);

my $res = $dmm->search(
    site    => 'DMM.co.jp',
);

ok !$res->is_success, 'failed';
ok $res->cause, 'has error cause';

ok $dmm->last_response;
isa_ok $dmm->last_response, 'Furl::Response';

done_testing;
