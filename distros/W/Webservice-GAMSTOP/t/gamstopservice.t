package t::gamstopservice;

use Mojolicious::Lite;
use Test::More;
use Test::Mojo;

post '/get_exclusion' => sub {
    my $c = shift;

    # api key is mandatory and needs to be passed in header
    return $c->render(
        text   => 'Forbidden',
        status => 403,
    ) unless $c->req->headers->header('X-API-Key');

    # need to be equal else error out
    return $c->render(
        text   => 'Forbidden',
        status => 403,
        )
        if ($c->req->headers->header('X-API-Key')
        and $c->req->headers->header('X-API-Key') ne 'dummy');

    my $params = $c->req->params->to_hash;

    return $c->render(
        text   => 'Bad Request',
        status => 400,
    ) unless keys %$params;

    return $c->render(
        text   => 'Bad Request',
        status => 400,
    ) unless exists $params->{firstname};

    return $c->render(
        text   => 'Bad Request',
        status => 400,
    ) unless exists $params->{lastName};

    return $c->render(
        text   => 'Bad Request',
        status => 400,
    ) unless exists $params->{dateOfBirth};

    return $c->render(
        text   => 'Bad Request',
        status => 400,
    ) unless exists $params->{email};

    return $c->render(
        text   => 'Bad Request',
        status => 400,
    ) unless exists $params->{postcode};

    $c->render(text => 'Success');
};

my $t;
subtest 'header validation' => sub {
    $t = Test::Mojo->new('t::gamstopservice');
    $t->post_ok('/get_exclusion')->status_is(403)->content_like(qr/Forbidden/);

    $t = Test::Mojo->new('t::gamstopservice');

    $t->ua->on(
        start => sub {
            my ($ua, $tx) = @_;
            $tx->req->headers->header('X-API-Key' => 'random');
        });

    $t->post_ok('/get_exclusion')->status_is(403)->content_like(qr/Forbidden/);
};

subtest 'params validations' => sub {
    subtest 'empty params' => sub {
        $t = Test::Mojo->new('t::gamstopservice');

        $t->ua->on(
            start => sub {
                my ($ua, $tx) = @_;
                $tx->req->headers->header('X-API-Key' => 'dummy');
            });

        $t->post_ok('/get_exclusion' => form => {})->status_is(400)->content_like(qr/Bad Request/);
    };

    subtest 'missing required params' => sub {
        $t = Test::Mojo->new('t::gamstopservice');

        $t->ua->on(
            start => sub {
                my ($ua, $tx) = @_;
                $tx->req->headers->header('X-API-Key' => 'dummy');
            });

        $t->post_ok(
            '/get_exclusion' => form => {
                lastName    => 'Potter',
                dateOfBirth => '1970-01-01',
                email       => 'harry.potter@example.com',
                postcode    => 'hp11aa'
            })->status_is(400)->content_like(qr/Bad Request/);

        $t->post_ok(
            '/get_exclusion' => form => {
                firstname   => 'Harry',
                dateOfBirth => '1970-01-01',
                email       => 'harry.potter@example.com',
                postcode    => 'hp11aa'
            })->status_is(400)->content_like(qr/Bad Request/);

        $t->post_ok(
            '/get_exclusion' => form => {
                firstname => 'Harry',
                lastName  => 'Potter',
                email     => 'harry.potter@example.com',
                postcode  => 'hp11aa'
            })->status_is(400)->content_like(qr/Bad Request/);

        $t->post_ok(
            '/get_exclusion' => form => {
                firstname   => 'Harry',
                lastName    => 'Potter',
                dateOfBirth => '1970-01-01',
                email       => 'harry.potter@example.com'
            })->status_is(400)->content_like(qr/Bad Request/);
    };

    subtest 'successful request' => sub {
        $t = Test::Mojo->new('t::gamstopservice');

        $t->ua->on(
            start => sub {
                my ($ua, $tx) = @_;
                $tx->req->headers->header('X-API-Key' => 'dummy');
            });

        $t->post_ok(
            '/get_exclusion' => form => {
                firstname   => 'Harry',
                lastName    => 'Potter',
                dateOfBirth => '1970-01-01',
                email       => 'harry.potter@example.com',
                postcode    => 'hp11aa'
            })->status_is(200)->content_like(qr/Success/);
    };
};

done_testing;
