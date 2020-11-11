package TestHTTPUAPIMixin;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;
use autodie;

use parent (
    'TestHTTPCpanelMixin',
    'Test::Class',
);

use Test::More;
use Test::Deep;
use Test::Fatal;

sub no_answer_uapi : Tests(1) {
    my ($self) = shift;

    my $remote_cp = $self->CREATE(
        service => 'cpanel',

        credentials => {
            username  => 'johnny',
            api_token => 'MYTOKEN',
        },
    );

    cmp_deeply(
        exception { $self->AWAIT( $remote_cp->call_uapi( 'Doomed', 'noanswer' ) ) },
        Isa('cPanel::APIClient::X::SubTransport'),
        'expected error object',
    );

    return;
}

sub forbidden_uapi : Tests(1) {
    my ($self) = shift;

    my $remote_cp = $self->CREATE(
        service => 'cpanel',

        credentials => {
            username  => 'johnny',
            api_token => 'MYTOKEN',
        },
    );

    my $err = exception { $self->AWAIT( $remote_cp->call_uapi( 'Doomed', 'forbidden' ) ) };

    cmp_deeply(
        $err,
        all(
            methods(
                [ isa => 'cPanel::APIClient::X::HTTP' ] => bool(1),
                get_message => all(
                    re(qr<403>),
                    re(qr<Go away>i),
                ),
            ),
            all(
                re(qr<403>),
                re(qr<Go away>i),
            ),
        ),
        'expected error object',
    ) or diag explain $err;

    return;
}

sub messages_from_response_object : Tests(1) {
    my ($self) = @_;

    my $remote_cp = $self->CREATE(
        service => 'cpanel',

        credentials => {
            username  => 'johnny',
            api_token => 'MYTOKEN',
        },
    );

    my $got = $self->AWAIT(
        $remote_cp->call_uapi(
            'Email',
            'fail_errors_warnings_messages',
        )
    );

    cmp_deeply(
        $got,
        all(
            methods(
                succeeded            => bool(0),
                get_errors_as_string => re(qr<err1.*err2>s),
            ),
            listmethods(
                get_errors   => [ 'err1',     'err2' ],
                get_warnings => [ 'warn1',    'warn2' ],
                get_messages => [ 'message1', 'message2' ],
            ),
        ),
        'response properties as expected',
    ) or diag explain $got;

    return;
}

sub simple_with_token : Tests(2) {
    my ($self) = shift;

    my $remote_cp = $self->CREATE(
        service => 'cpanel',

        credentials => {
            username  => 'johnny',
            api_token => 'MYTOKEN',
        },
    );

    my $got = $self->AWAIT( $remote_cp->call_uapi( 'Email', 'list_forwarders' ) );

    cmp_deeply(
        $got,
        all(
            methods(
                [ isa => 'cPanel::APIClient::Response::UAPI' ] => bool(1),
                succeeded => 1,
                get_data  => {
                    content => q<>,
                    method  => 'POST',
                    uri     => '/execute/Email/list_forwarders',
                    headers => ignore(),
                },
            ),
            listmethods(
                get_errors   => [],
                get_warnings => [],
                get_messages => [],
            ),
        ),
        'UAPI response',
    ) or diag explain $got;

    my %headers = @{ $got->get_data()->{'headers'} };

    cmp_deeply(
        \%headers,
        superhashof(
            {
                'Authorization' => 'cpanel johnny:MYTOKEN',
                'Content-Type'  => 'application/x-www-form-urlencoded',
            }
        ),
        'headers',
    );

    return;
}

sub why_u_no_create_session { undef }

sub simple_with_password_and_tfa_token : Tests(4) {
    my ($self) = shift;

  SKIP: {
        my $why_skip = $self->why_u_no_create_session();

        skip $why_skip, $self->num_tests() if $why_skip;

        my $remote_cp = $self->CREATE(
            service => 'cpanel',

            credentials => {
                username  => 'johnny',
                password  => 'mysecret',
                tfa_token => 'mytfa',
            },
        );

        my $got = $self->AWAIT( $remote_cp->call_uapi( 'Email', 'list_forwarders' ) );

        cmp_deeply(
            $got,
            all(
                methods(
                    [ isa => 'cPanel::APIClient::Response::UAPI' ] => bool(1),
                    succeeded => 1,
                    get_data  => {
                        content => q<>,
                        method  => 'POST',
                        uri     => '/cpses123123123/execute/Email/list_forwarders',
                        headers => ignore(),
                    },
                ),
                listmethods(
                    get_errors   => [],
                    get_warnings => [],
                    get_messages => [],
                ),
            ),
            'UAPI response',
        ) or diag explain $got;

        my %headers = @{ $got->get_data()->{'headers'} };

        cmp_deeply(
            \%headers,
            superhashof(
                {
                    'Content-Type' => 'application/x-www-form-urlencoded',
                    Cookie         => ignore(),
                }
            ),
            'headers',
        ) or diag explain \%headers;

        my @cookies = sort split m<\s*;\s*>, $headers{'Cookie'};

        cmp_bag(
            \@cookies,
            [
                'cpsession=johnny%3a3KCfM88PHoZ4MoUf%2ce95011e2b6a51118250861a505638a8c',
                ignore(),
            ],
            'session cookie sent',
        );

        $cookies[1] =~ s<\Alogin=><> or die "bad login cookie: $cookies[1]";
        my $login = URI::Escape::uri_unescape( $cookies[1] );
        my @params = split m<&>, $login;

        cmp_bag(
            \@params,
            [
                'user=johnny',
                'pass=mysecret',
                'tfa_token=mytfa',
                'login_only=1',
            ],
            'login parameters',
        ) or diag explain \@params;
    }

    return;
}

sub simple_with_password : Tests(2) {
    my ($self) = shift;

    my $remote_cp = $self->CREATE(
        service => 'cpanel',

        credentials => {
            username => 'johnny',
            password => 'mysecret',
        },
    );

    my $got = $self->AWAIT( $remote_cp->call_uapi( 'Email', 'list_forwarders' ) );

    cmp_deeply(
        $got,
        all(
            methods(
                [ isa => 'cPanel::APIClient::Response::UAPI' ] => bool(1),
                succeeded => 1,
                get_data  => {
                    content => q<>,
                    method  => 'POST',
                    uri     => '/execute/Email/list_forwarders',
                    headers => ignore(),
                },
            ),
            listmethods(
                get_errors   => [],
                get_warnings => [],
                get_messages => [],
            ),
        ),
        'UAPI response',
    ) or diag explain $got;

    my %headers = @{ $got->get_data()->{'headers'} };

    cmp_deeply(
        \%headers,
        superhashof(
            {
                'Content-Type' => 'application/x-www-form-urlencoded',
                Authorization  => 'Basic am9obm55Om15c2VjcmV0',
            }
        ),
        'headers',
    ) or diag explain \%headers;

    return;
}

sub with_payload : Tests(2) {
    my ($self) = shift;

    my $remote_cp = $self->CREATE(
        service => 'cpanel',

        credentials => {
            username  => 'johnny',
            api_token => 'MYTOKEN',
        },
    );

    my $got = $self->AWAIT(
        $remote_cp->call_uapi(
            'Email', 'list_forwarders',
            {
                foo => 1,
                bar => [ 2, 3, '"' ],
                baz => q<>,
                '"' => '"',
            },
        )
    );

    my $content = $got->get_data()->{'content'};
    my @pieces = split m<&>, $content, -1;

    cmp_bag(
        \@pieces,
        [
            'foo=1',
            'bar=2',
            'bar=3',
            'bar=%22',
            'baz=',
            '%22=%22',
        ],
        'UAPI response - content',
    ) or diag explain $got;

    like(
        $content,
        qr<bar=2.+bar=3.+bar=%22>,
        '“bar” args are in correct order',
    );

    return;
}

1;
