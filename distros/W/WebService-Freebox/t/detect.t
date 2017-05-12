use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN { use_ok('WebService::Freebox'); }

throws_ok { WebService::Freebox->new() } qr/is required/, 'missing attributes detected';

SKIP: {
    my $app_token = $ENV{FREEBOX_APP_TOKEN};

    skip 'FREEBOX_APP_TOKEN env var must contain the app token', 1
        unless defined $app_token;

    my $fb = WebService::Freebox->new(
                app_id => 'org.cpan.freebox.test',
                app_version => '1.0',
                app_token => $app_token
            );
    isa_ok($fb, 'WebService::Freebox');

    note("Found Freebox implementing API v$fb->{_api_version}.");

    can_ok($fb, qw(authorize));
}

done_testing();
