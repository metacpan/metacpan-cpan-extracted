use strict;
use warnings;
use Test::More;
use Test::Flatten;
use Test::SharedFork;
use Test::Fake::HTTPD;
use URI::Escape;
use WWW::Google::ClientLogin;
use WWW::Google::ClientLogin::Constants;

plan skip_all => 'THIS TEST IS NOT SUPPORTED ON YOUR OS' if $^O eq 'MSWin32';

sub new_client {
    WWW::Google::ClientLogin->new(
        email    => 'email',
        password => 'password',
        service  => 'service',
    );
}

sub parse_request {
    my $content = shift;
    return { map { uri_unescape($_) } map { split '=', $_, 2 } split '&', $content };
}

sub default_request_params {
    return {
        accountType => 'HOSTED_OR_GOOGLE',
        Email       => 'email',
        Passwd      => 'password',
        service     => 'service',
        source      => 'WWW::Google::ClientLogin_'.$WWW::Google::ClientLogin::VERSION,
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

subtest 'success' => sub {
    my $httpd = run_http_server {
        my $req = shift;
        my $params = parse_request($req->content);
        is_deeply $params, default_request_params();

        my $content = create_response_content(
            SID  => 'sid',
            LSID => 'lsid',
            Auth => 'auth_token',
        );
        return create_response(200 => $content);
    };
    local $WWW::Google::ClientLogin::URL = $httpd->endpoint;

    my $client = new_client();
    my $res = $client->authenticate();

    isa_ok $res, 'WWW::Google::ClientLogin::Response';
    ok $res->is_success;
    ok !$res->is_error;
    ok !$res->has_error;
    is $res->code, 200;
    is $res->message, 'OK';
    is $res->auth_token, 'auth_token';
    is $res->sid, 'sid';
    is $res->lsid, 'lsid';
};

subtest 'success with captcha' => sub {
    my $httpd = run_http_server {
        my $req = shift;
        my $params = parse_request($req->content);
        my $expects = default_request_params();
        $expects->{logintoken}   = 'logintoken';
        $expects->{logincaptcha} = 'logincaptcha';
        is_deeply $params, $expects;

        my $content = create_response_content(
            SID  => 'sid',
            LSID => 'lsid',
            Auth => 'auth_token',
        );
        return create_response(200 => $content);
    };
    local $WWW::Google::ClientLogin::URL = $httpd->endpoint;

    my $client = new_client();
    $client->{logintoken}   = 'logintoken';
    $client->{logincaptcha} = 'logincaptcha';
    my $res = $client->authenticate();

    isa_ok $res, 'WWW::Google::ClientLogin::Response';
    ok $res->is_success;
    ok !$res->is_error;
    ok !$res->has_error;
    is $res->code, 200;
    is $res->message, 'OK';
    is $res->auth_token, 'auth_token';
    is $res->sid, 'sid';
    is $res->lsid, 'lsid';
};

subtest 'forbidden' => sub {
    my $httpd = run_http_server {
        my $req = shift;
        my $params = parse_request($req->content);
        is_deeply $params, default_request_params();

        my $content = create_response_content(
            Error => 'BadAuthentication',
        );
        return create_response(403 => $content);
    };
    local $WWW::Google::ClientLogin::URL = $httpd->endpoint;

    my $client = new_client();
    my $res = $client->authenticate();

    isa_ok $res, 'WWW::Google::ClientLogin::Response';
    ok !$res->is_success;
    ok $res->is_error;
    ok $res->has_error;
    is $res->code, 403;
    is $res->message, 'Forbidden';
    is $res->error_code, BadAuthentication;
    is $res->auth_token, undef;
    is $res->sid, undef;
    is $res->lsid, undef;
};

subtest 'forbidden (CaptchaRequired)' => sub {
    my $httpd = run_http_server {
        my $req = shift;
        my $params = parse_request($req->content);
        is_deeply $params, default_request_params();

        my $content = create_response_content(
            Error        => 'CaptchaRequired',
            CaptchaToken => 'captcha_token',
            CaptchaUrl   => 'captcha_url',
        );
        return create_response(403 => $content);
    };
    local $WWW::Google::ClientLogin::URL = $httpd->endpoint;

    my $client = new_client();
    my $res = $client->authenticate();

    isa_ok $res, 'WWW::Google::ClientLogin::Response';
    ok !$res->is_success;
    ok $res->is_error;
    ok $res->has_error;
    is $res->code, 403;
    is $res->message, 'Forbidden';
    is $res->error_code, CaptchaRequired;
    ok $res->is_captcha_required;
    is $res->auth_token, undef;
    is $res->sid, undef;
    is $res->lsid, undef;
    is $res->captcha_token, 'captcha_token';
    is $res->captcha_url, 'captcha_url';
};

subtest 'internal server error' => sub {
    my $httpd = run_http_server {
        my $req = shift;
        my $params = parse_request($req->content);
        is_deeply $params, default_request_params();

        return create_response(500 => 'oops=oops');
    };
    local $WWW::Google::ClientLogin::URL = $httpd->endpoint;

    my $client = new_client();
    my $res = $client->authenticate();

    isa_ok $res, 'WWW::Google::ClientLogin::Response';
    ok !$res->is_success;
    ok $res->is_error;
    ok $res->has_error;
    is $res->code, 500;
    is $res->message, 'Internal Server Error';
    is $res->auth_token, undef;
    is $res->sid, undef;
    is $res->lsid, undef;
};

done_testing;
