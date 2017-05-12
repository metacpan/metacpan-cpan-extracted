use Test::More;

use WWW::SEOmoz;

SKIP: {
    skip 'Set environment variable SEOMOZ_ACCESS_ID and SEOMOZ_SECRET_KEY for testing', 5
        unless defined $ENV{SEOMOZ_ACCESS_ID} && $ENV{SEOMOZ_SECRET_KEY};

    my $seomoz = WWW::SEOmoz->new({
        access_id => $ENV{SEOMOZ_ACCESS_ID},
        secret_key => $ENV{SEOMOZ_SECRET_KEY},
    });

    ok($seomoz, 'Got something');
    isa_ok($seomoz, 'WWW::SEOmoz');
    is($seomoz->access_id, $ENV{SEOMOZ_ACCESS_ID}, 'Correct access id');
    is($seomoz->secret_key, $ENV{SEOMOZ_SECRET_KEY}, 'Correct secret key');
    isa_ok($seomoz->ua, 'LWP::UserAgent');
    ok($seomoz->url_metrics('www.seomoz.org/'), 'Got some url metrics');
    ok($seomoz->links('www.seomoz.org/'), 'Got some link metrics');
}

done_testing;
