use Test::More;

use WWW::Mixcloud;

SKIP: {
    skip 'Set environment variable MIXCLOUD_KEY 
        and MIXCLOUD_SECRET for testing', 10
        unless defined $ENV{MIXCLOUD_KEY} && $ENV{MIXCLOUD_SECRET};

    my $mixcloud = WWW::Mixcloud->new({
        api_key    => $ENV{MIXCLOUD_KEY},
        api_secret => $ENV{MIXCLOUD_SECRET},
    });

    ok($mixcloud, 'Got something');
    isa_ok($mixcloud, 'WWW::Mixcloud');
    is($mixcloud->api_key, $ENV{MIXCLOUD_KEY}, 'Correct API key');
    is($mixcloud->api_secret, $ENV{MIXCLOUD_SECRET}, 'Correct secret key');
    isa_ok($mixcloud->ua, 'LWP::UserAgent');
    ok(
        $mixcloud->get_cloudcast('http://www.mixcloud.com/spartacus/party-time/'),
        'Got some cloudcast data'
    );
    ok(
        $mixcloud->get_user('http://www.mixcloud.com/spartacus/'),
        'Got some mixcloud user data'
    );
    ok(
        $mixcloud->get_tag('http://api.mixcloud.com/tag/funk/'),
        'Got some mixcloud tag data'
    );
    ok(
        $mixcloud->get_artist('http://api.mixcloud.com/artist/aphex-twin/'),
        'Got some mixcloud artist data'
    );
    ok(
        $mixcloud->get_track('http://api.mixcloud.com/track/bonobo/ketto/'),
        'Got some mixcloud track data'
    );
    ok(
        $mixcloud->get_category('http://api.mixcloud.com/categories/ambient/'),
        'Got some mixcloud category data'
    );
}

done_testing;
