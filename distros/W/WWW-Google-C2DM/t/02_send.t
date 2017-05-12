use strict;
use warnings;
use Test::More;
use Test::Flatten;
use Test::SharedFork;
use Test::Fake::HTTPD;
use URI::Escape;
use WWW::Google::C2DM;
use WWW::Google::C2DM::Constants;

plan skip_all => 'THIS TEST IS NOT SUPPORTED ON YOUR OS' if $^O eq 'MSWin32';

sub new_c2dnm {
    WWW::Google::C2DM->new(auth_token => 'auth_token');
}

sub parse_request {
    my $content = shift;
    return { map { split '=', $_, 2 } split '&', $content };
}

sub default_request_params {
    return {
        registration_id => 'registration_id',
        collapse_key    => 'collapse_key',
    };
}

sub create_response_content {
    my %params = @_;
    return join "\n", map { sprintf '%s=%s', $_, $params{$_} } keys %params;
}

sub create_response {
    my ($code, $content) = @_;
    return [$code, [
        'Content-Length' => length($content),
        'Content-Type'   => 'text/plain',
    ], [$content]];
}

subtest 'required registration_id' => sub {
    eval { new_c2dnm->send };
    like $@, qr/Usage: .*registration_id =>/;
};

subtest 'required collapse_key' => sub {
    eval { new_c2dnm->send(registration_id => 'registration_id') };
    like $@, qr/Usage: .*collapse_key =>/;
};

subtest 'not allow collapse_key = q{}' => sub {
    eval {
        new_c2dnm->send(
            registration_id => 'registration_id',
            collapse_key    => '',
        );
    };
    like $@, qr/Usage: .*collapse_key =>/;
};

subtest 'allow collapse_key = 0 (but data is invalid)' => sub {
    eval {
        new_c2dnm->send(
            registration_id => 'registration_id',
            collapse_key    => 0,
            data            => 'foo',
        );
    };
    like $@, qr/data parameter must be HASHREF/;
};

subtest 'data is invalid' => sub {
    eval {
        new_c2dnm->send(
            registration_id => 'registration_id',
            collapse_key    => 'collapse_key',
            data            => 'foo',
        );
    };
    like $@, qr/data parameter must be HASHREF/;
};

subtest 'success' => sub {
    my $httpd = run_http_server {
        my $req = shift;

        my $params = parse_request($req->content);
        is_deeply $params, default_request_params();
        is $req->header('Content-Type'), 'application/x-www-form-urlencoded';
        is $req->header('Authorization'), 'GoogleLogin auth=auth_token';

        my $content = create_response_content(id => 'id');
        return create_response(200 => $content);
    };

    local $WWW::Google::C2DM::URL = $httpd->endpoint;
    my $res = new_c2dnm->send(
        registration_id => 'registration_id',
        collapse_key    => 'collapse_key',
    );
    isa_ok $res, 'WWW::Google::C2DM::Response';
    isa_ok $res->http_response, 'HTTP::Response';
    ok $res->is_success;
    is $res->code, 200;
    is $res->message, 'OK';
    is $res->status_line, '200 OK';

    ok !$res->is_error;
    ok !$res->has_error;
    is $res->error_code, '';
    is $res->id, 'id';
    is_deeply $res->params, { id => 'id' };
};

subtest 'with data' => sub {
    my $httpd = run_http_server {
        my $req = shift;

        my $params = parse_request($req->content);
        is_deeply $params, {
            %{default_request_params()},
            'data.message' => 'message',
            'data.foo'     => 'bar',
            'data.hoge'    => 'fuga',
            'data.mbyte'   => "%E5%BF%8D%E8%80%85",
        };
        is $req->header('Content-Type'), 'application/x-www-form-urlencoded';
        is $req->header('Authorization'), 'GoogleLogin auth=auth_token';

        my $content = create_response_content(id => 'id');
        return create_response(200 => $content);
    };

    local $WWW::Google::C2DM::URL = $httpd->endpoint;
    my $res = new_c2dnm->send(
        registration_id => 'registration_id',
        collapse_key    => 'collapse_key',
        'data.message'  => 'message',
        data            => {
            foo   => 'bar',
            hoge  => 'fuga',
            mbyte => "\x{5fcd}\x{8005}",
        },
    );
    isa_ok $res, 'WWW::Google::C2DM::Response';
    isa_ok $res->http_response, 'HTTP::Response';
    ok $res->is_success;
    ok !$res->is_error;
    ok !$res->has_error;
    is $res->error_code, '';
    is $res->id, 'id';
};

subtest 'error 503' => sub {
    my $httpd = run_http_server {
        my $req = shift;

        my $params = parse_request($req->content);
        is_deeply $params, default_request_params();
        is $req->header('Content-Type'), 'application/x-www-form-urlencoded';
        is $req->header('Authorization'), 'GoogleLogin auth=auth_token';

        return create_response(503 => 'Service Temporarily Unavailable');
    };

    local $WWW::Google::C2DM::URL = $httpd->endpoint;
    my $res = new_c2dnm->send(
        registration_id => 'registration_id',
        collapse_key    => 'collapse_key',
    );
    isa_ok $res, 'WWW::Google::C2DM::Response';
    isa_ok $res->http_response, 'HTTP::Response';
    ok !$res->is_success;
    ok $res->is_error;
    ok $res->has_error;
    is $res->error_code, '';
    is $res->id, undef;
};

subtest '200 but error' => sub {
    my $httpd = run_http_server {
        my $req = shift;

        my $params = parse_request($req->content);
        is_deeply $params, default_request_params();
        is $req->header('Content-Type'), 'application/x-www-form-urlencoded';
        is $req->header('Authorization'), 'GoogleLogin auth=auth_token';

        my $content = create_response_content(Error => 'QuotaExceeded');
        return create_response(200 => $content);
    };

    local $WWW::Google::C2DM::URL = $httpd->endpoint;
    my $res = new_c2dnm->send(
        registration_id => 'registration_id',
        collapse_key    => 'collapse_key',
    );
    isa_ok $res, 'WWW::Google::C2DM::Response';
    isa_ok $res->http_response, 'HTTP::Response';
    ok !$res->is_success;
    ok $res->is_error;
    ok $res->has_error;
    is $res->error_code, QuotaExceeded;
    is $res->id, undef;
};

done_testing;
