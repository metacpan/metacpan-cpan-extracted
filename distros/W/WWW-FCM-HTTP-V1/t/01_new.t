use strict;
use warnings;
use Test::More;

use WWW::FCM::HTTP::V1;

subtest 'api_url and api_key_json required' => sub {
    eval { WWW::FCM::HTTP::V1->new };
    like $@, qr/Usage: WWW::FCM::HTTP::V1->new\(\{ api_url => \$api_url, api_key_json => \$api_key_json \}\)/;
};

subtest 'api_url must be defined' => sub {
    eval { WWW::FCM::HTTP::V1->new(api_url => undef, api_key_json => '{}') };
    like $@, qr/Usage: WWW::FCM::HTTP::V1->new\(\{ api_url => \$api_url, api_key_json => \$api_key_json \}\)/;
};

subtest 'api_key_json must be defined' => sub {
    eval { WWW::FCM::HTTP::V1->new(api_url => 'api_url', api_key_json => undef) };
    like $@, qr/Usage: WWW::FCM::HTTP::V1->new\(\{ api_url => \$api_url, api_key_json => \$api_key_json \}\)/;
};

subtest 'success' => sub {
    my $fcm = WWW::FCM::HTTP::V1->new(api_url => 'api_url', api_key_json => '{ "foo": "bar" }');
    isa_ok $fcm, 'WWW::FCM::HTTP::V1';
    isa_ok $fcm->{sender}, 'WWW::FCM::HTTP::V1::OAuth';
    is $fcm->{api_url}, 'api_url';
    is $fcm->{sender}->{api_key_json}, '{ "foo": "bar" }';
};

subtest 'success (hashref)' => sub {
    my $fcm = WWW::FCM::HTTP::V1->new({ api_url => 'api_url', api_key_json => '{ "foo": "bar" }' });
    isa_ok $fcm, 'WWW::FCM::HTTP::V1';
    isa_ok $fcm->{sender}, 'WWW::FCM::HTTP::V1::OAuth';
    is $fcm->{api_url}, 'api_url';
    is $fcm->{sender}->{api_key_json}, '{ "foo": "bar" }';
};

subtest 'set sender' => sub {
    my $fcm = WWW::FCM::HTTP::V1->new(
        api_url      => 'https://fcm.googleapis.com/v1/projects/sample-myproject/messages:send',
        api_key_json => '{}',
        sender       => WWW::FCM::HTTP::V1::OAuth->new(api_key_json => '{ "type": "service_account" }'),
    );
    isa_ok $fcm, 'WWW::FCM::HTTP::V1';
    isa_ok $fcm->{sender}, 'WWW::FCM::HTTP::V1::OAuth';
    is $fcm->{api_url}, 'https://fcm.googleapis.com/v1/projects/sample-myproject/messages:send';
    is $fcm->{sender}->{api_key_json}, '{ "type": "service_account" }';
};

done_testing;

