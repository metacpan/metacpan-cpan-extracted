use strict;
use warnings;
use Test::Tester; # Call before any other Test::Builder-based modules
use Test::More;
use Test::Deep qw( cmp_deeply methods isa re );
use Test::Warnings qw(:no_end_test warnings);
use parent qw( Test::Class );

use Plack::Request;
use Test::WWW::Stub;
use LWP::UserAgent;

sub ua { LWP::UserAgent->new; }

sub test_pass {
    my ($sub) = shift;
    my ($premature, @results) = run_tests( $sub );
    return $results[0]->{ok};
}

sub lwp_protocol : Tests {
    subtest 'imported' => sub {
        my $warnings = [ warnings { ua()->get('http://example.com/') } ];
        cmp_deeply $warnings, [ re('Unexpected external access:') ], 'warnings appeared';
    };
    subtest 'imported and unstubbed' => sub {
        my $g = Test::WWW::Stub->unstub;
        my $warnings = [ warnings { ua()->get('http://example.com/') } ];
        cmp_deeply $warnings, [], 'no warnings';
    };
    subtest 'unstubbed and imported multiple time' => sub {
        Test::WWW::Stub->import;
        my $g = Test::WWW::Stub->unstub;
        my $warnings = [ warnings { ua()->get('http://example.com/') } ];
        cmp_deeply $warnings, [], 'no warnings';
    };
}

sub register : Tests {
    my $self = shift;

    subtest 'register string uri and arrayref res' => sub {
        {
            my $g = Test::WWW::Stub->register(q<http://example.com/TEST/>,  [ 200, [], [ '1' ] ]);

            my $res = $self->ua->get('http://example.com/TEST/');
            ok $res->is_success;
            is $res->content, '1';

            ok $self->ua->get('http://example.com/TEST')->is_error, 'match only with exact same uri';
        }

        ok $self->ua->get('http://example.com/TEST/')->is_error, 'error outside guard';
    };

    subtest 'register regex uri and arrayref res' => sub {
        my $g = Test::WWW::Stub->register(qr<\A\Qhttp://example.com/MATCH/\E>,  [ 200, [], [ '1' ] ]);

        my $res = $self->ua->get('http://example.com/MATCH/hoge');
        ok $res->is_success, 'match according to regexp';
        is $res->content, '1';

        ok $self->ua->get('http://example.com/NONMATCH/hoge')->is_error;
    };

    subtest 'register string uri and PSGI app' => sub {
        my $app = sub {
            my $env = shift;
            my $req = Plack::Request->new($env);
            my $headers = [
                'X-Test-Req-Uri' => $req->uri->as_string,
            ];
            return [ 200, $headers, [ 1 ] ];
        };
        my $g = Test::WWW::Stub->register(q<http://example.com/TEST> => $app);

        my $res = $self->ua->get('http://example.com/TEST');
        ok $res->is_success;
        is $res->header( 'X-Test-Req-Uri' ), 'http://example.com/TEST', 'app receives proper env';

        my $res_with_query = $self->ua->get('http://example.com/TEST?foo=bar');
        ok $res_with_query->is_success, 'query parameters are ignored on matching handlers,';
        is $res_with_query->header( 'X-Test-Req-Uri' ), 'http://example.com/TEST?foo=bar', 'But passed to app!';
    };

    subtest 'register without guard ' => sub {
        {
            Test::WWW::Stub->register(q<http://example.com/HOGE/>,  [ 200, [], [ '1' ] ]);
            ok $self->ua->get('http://example.com/HOGE/')->is_success, 'stub works when registered without guard';
        }

        ok $self->ua->get('http://example.com/HOGE/')->is_success, 'when registered without guard, stub works outside of scope too.';
    };

    subtest 'override stub' => sub {
        my $g1 = Test::WWW::Stub->register(q<http://example.com/OVERRIDE> => [ 200, [], [] ]);
        {
            my $g2 = Test::WWW::Stub->register(q<http://example.com/OVERRIDE> => [ 500, [], [] ]);
            is $self->ua->get('http://example.com/OVERRIDE')->code, 500, 'override stub';
            my $g3 = Test::WWW::Stub->register(q<http://example.com/OVERRIDE> => [ 400, [], [] ]);
            is $self->ua->get('http://example.com/OVERRIDE')->code, 400, 'override stub again in same scope';
        }
        is $self->ua->get('http://example.com/OVERRIDE')->code, 200, 'restore stub when out of scope';
    };

    subtest 'use shorter pattern' => sub {
        my $g1 = Test::WWW::Stub->register(q<http://example.com/TEST/LONG_PATTERN> => [ 200, [], ['0'] ]);
        my $g2 = Test::WWW::Stub->register(q<http://example.com/TEST/> => [ 200, [], ['1'] ]);

        my $res = $self->ua->get('http://example.com/TEST/');
        is $res->content, '1';
    };
}

sub unstub : Tests {
    my $self = shift;

    my $stub_g = Test::WWW::Stub->register('http://example.com/TEST', [ 200, [], ['2'] ]);
    ok $self->ua->get('http://example.com/TEST')->is_success;

    {
        my $unstub_g = Test::WWW::Stub->unstub;
        ok $self->ua->get('http://example.com/TEST')->is_error, 'unstubbed';
    }

    ok $self->ua->get('http://example.com/TEST')->is_success, 're-registered stub';

    subtest 'unstub again' => sub {
        {
            my $unstub_g = Test::WWW::Stub->unstub;
            ok $self->ua->get('http://example.com/TEST')->is_error, 'unstubbed';
        }

        ok $self->ua->get('http://example.com/TEST')->is_success, 're-registered stub';
    }
}

sub last_request_for : Tests {
    my ($self) = @_;

    # at first reset requests
    Test::WWW::Stub->clear_requests;

    my $stub_g = Test::WWW::Stub->register(qr<\A\Qhttp://request.example.com/\E>, [ 200, [], ['okok'] ]);

    $self->ua->get('http://request.example.com/FIRST', 'X-Request-Id' => 1);
    $self->ua->get('http://request.example.com/FIRST?k=v', 'X-Request-Id' => 2);
    $self->ua->get('http://request.example.com/SECOND');

    my $req_get_first = Test::WWW::Stub->last_request_for('GET', 'http://request.example.com/FIRST');
    cmp_deeply $req_get_first, isa('Plack::Request') & methods(
        request_uri => '/FIRST?k=v',
        ['header', 'X-Request-Id'] => 2,
    ), 'last request for given method and URL';

    my $req_get_second = Test::WWW::Stub->last_request_for('GET', 'http://request.example.com/SECOND');
    cmp_deeply $req_get_second, isa('Plack::Request') & methods(
        request_uri => '/SECOND',
    ), 'last request for given method and URL';

    my $req_post_first = Test::WWW::Stub->last_request_for('POST', 'http://request.example.com/FIRST');
    is $req_post_first, undef, 'URL is matched, but method is NOT matched';
}

sub request : Tests {
    my $self = shift;

    # at first reset requests
    Test::WWW::Stub->clear_requests;
    cmp_deeply [ Test::WWW::Stub->requests], [];

    my $stub_g = Test::WWW::Stub->register(qr<\A\Qhttp://request.example.com/\E>, [ 200, [], ['okok'] ]);

    $self->ua->get('http://request.example.com/FIRST');
    $self->ua->get('http://request.example.com/SECOND');

    my $requested_requests = [ Test::WWW::Stub->requests ];
    is scalar @$requested_requests, 2;

    ok test_pass(
        sub{ Test::WWW::Stub->requested_ok('GET', 'http://request.example.com/FIRST') }
    ), 'passes when calling with requested method-uri pair';

    ok ! test_pass(
        sub{ Test::WWW::Stub->requested_ok('GET', 'http://request.example.com/NOTREQUESTED') }
    ), 'fails when calling with not-requested uri';

    ok ! test_pass(
        sub{ Test::WWW::Stub->requested_ok('POST', 'http://request.example.com/FIRST') }
    ), 'We requested only by GET, so requeted_ok("POST", ..) fails';

    subtest 'last_request' => sub {
        ok my $last_req = Test::WWW::Stub->last_request;
        is $last_req->method, 'GET';
        is $last_req->uri, 'http://request.example.com/SECOND';
    };

    Test::WWW::Stub->clear_requests;
    cmp_deeply [ Test::WWW::Stub->requests], [], 'properly cleared';

    ok !Test::WWW::Stub->last_request, 'last_request also cleared';
}

__PACKAGE__->runtests;
