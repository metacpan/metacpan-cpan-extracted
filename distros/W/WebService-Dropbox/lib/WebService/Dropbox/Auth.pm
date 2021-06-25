package WebService::Dropbox::Auth;
use strict;
use warnings;
use parent qw(Exporter);

our @EXPORT = do {
    no strict 'refs';
    grep { $_ !~ qr{ \A [A-Z]+ \z }xms } keys %{ __PACKAGE__ . '::' };
};

# https://www.dropbox.com/developers/documentation/http/documentation#oauth2-authorize
sub authorize {
    my ($self, $params) = @_;

    $params ||= {};
    $params->{response_type} ||= 'code';

    my $url = URI->new('https://www.dropbox.com/oauth2/authorize');
    $url->query_form(
        client_id => $self->key,
        %$params,
    );
    $url->as_string;
}

# https://www.dropbox.com/developers/documentation/http/documentation#oauth2-token
sub token {
    my ($self, $code, $redirect_uri) = @_;

    my $data = $self->api({
        url => 'https://api.dropboxapi.com/oauth2/token',
        params => {
            client_id     => $self->key,
            client_secret => $self->secret,
            grant_type    => 'authorization_code',
            code          => $code,
            ( $redirect_uri ? ( redirect_uri => $redirect_uri ) : () ),
        },
    });

    if ($data && $data->{access_token}) {
        $self->access_token($data->{access_token});
    }

    $data;
}

# https://www.dropbox.com/developers/documentation/http/documentation#oauth2-token
# This uses the token method with a refresh token to get an updated access token.
sub refresh_access_token {
    my ($self, $refresh_token) = @_;

    my $data = $self->api({
        url => 'https://api.dropboxapi.com/oauth2/token',
        params => {
            client_id     => $self->key,
            client_secret => $self->secret,
            grant_type    => 'refresh_token',
            refresh_token => $refresh_token,
        },
    });

    # at this point the access token should be in $data
    # so set it like WebService::Dropbox::Auth::token does
    if ($data && $data->{access_token}) {
        $self->access_token($data->{access_token});
    }

    $data;
}

# https://www.dropbox.com/developers/documentation/http/documentation#auth-token-revoke
sub revoke {
    my ($self) = @_;

    my $res = $self->api({
        url => 'https://api.dropboxapi.com/2/auth/token/revoke',
    });

    $self->access_token(undef);

    $res;
}

1;
