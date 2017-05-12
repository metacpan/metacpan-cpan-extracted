use strict;
use warnings;
use Test::More;

BEGIN { use_ok('WebService::Freebox'); }

SKIP: {
    my $app_token = $ENV{FREEBOX_APP_TOKEN};

    skip 'FREEBOX_APP_TOKEN env var must contain the app token', 1
        unless defined $app_token;

    my $fb = WebService::Freebox->new(
                app_id => 'org.cpan.freebox.test',
                app_version => '1.0',
                app_token => $app_token
            );

    $fb->login($ENV{FREEBOX_SESSION_TOKEN});

    my $station_found = 0;
    my $fps = $fb->get_all_freeplugs();
    foreach my $fp (@$fps) {
        if ($fp->{net_role} eq 'sta') {
            $station_found = 1;
            last;
        }
    }

    ok( $station_found, 'found freeplug station' );
}

done_testing();

