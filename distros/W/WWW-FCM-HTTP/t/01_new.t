use strict;
use warnings;
use Test::More;

use WWW::FCM::HTTP;

subtest 'api_key required' => sub {
    eval { WWW::FCM::HTTP->new };
    like $@, qr/Usage: WWW::FCM::HTTP->new\(api_key => \$api_key\)/;
};

subtest 'success' => sub {
    my $fcm = WWW::FCM::HTTP->new(api_key => 'api_key');
    isa_ok $fcm, 'WWW::FCM::HTTP';
    isa_ok $fcm->{ua}, 'LWP::UserAgent';
    is $fcm->{api_key}, 'api_key';
    is $fcm->{api_url}, $WWW::FCM::HTTP::API_URL;
};

subtest 'sets all params' => sub {
    my $fcm = WWW::FCM::HTTP->new(
        api_key => 'api_key',
        api_url => 'http://example.com/',
        ua      => LWP::UserAgent->new,
    );
    isa_ok $fcm, 'WWW::FCM::HTTP';
    isa_ok $fcm->{ua}, 'LWP::UserAgent';
    is $fcm->{api_key}, 'api_key';
    is $fcm->{api_url}, 'http://example.com/';
};

done_testing;

