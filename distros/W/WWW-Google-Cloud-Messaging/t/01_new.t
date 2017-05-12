use strict;
use warnings;
use Test::More;

use WWW::Google::Cloud::Messaging;

subtest 'api_key required' => sub {
    eval { WWW::Google::Cloud::Messaging->new };
    like $@, qr/Usage: WWW::Google::Cloud::Messaging->new\(api_key => \$api_key\)/;
};

subtest 'success' => sub {
    my $gcm = WWW::Google::Cloud::Messaging->new(api_key => 'api_key');
    isa_ok $gcm, 'WWW::Google::Cloud::Messaging';
    isa_ok $gcm->{ua}, 'LWP::UserAgent';
    is $gcm->{api_key}, 'api_key';
    is $gcm->{api_url}, $WWW::Google::Cloud::Messaging::API_URL;
};

subtest 'sets all params' => sub {
    my $gcm = WWW::Google::Cloud::Messaging->new(
        api_key => 'api_key',
        api_url => 'http://example.com/',
        ua      => LWP::UserAgent->new,
    );
    isa_ok $gcm, 'WWW::Google::Cloud::Messaging';
    isa_ok $gcm->{ua}, 'LWP::UserAgent';
    is $gcm->{api_key}, 'api_key';
    is $gcm->{api_url}, 'http://example.com/';
};

done_testing;
