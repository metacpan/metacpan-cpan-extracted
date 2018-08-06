package Twitter::API::Trait::AppAuth;
# ABSTRACT: App-only (OAuth2) Authentication
$Twitter::API::Trait::AppAuth::VERSION = '1.0003';
use Moo::Role;
use Carp;
use URL::Encode qw/url_encode url_decode/;
use namespace::clean;

requires qw/
    _url_for access_token add_authorization api_url consumer_key
    consumer_secret request
/;

# private methods

sub oauth2_url_for {
    my $self = shift;

    $self->_url_for('', $self->api_url, 'oauth2', @_);
}

my $add_consumer_auth_header = sub {
    my ( $self, $req ) = @_;

    $req->headers->authorization_basic(
        $self->consumer_key, $self->consumer_secret);
};

# public methods

#pod =method oauth2_token
#pod
#pod Call the C<oauth2/token> endpoint to get a bearer token. The token is not
#pod stored in Twitter::API's state. If you want that, set the C<access_token>
#pod attribute with the returned token.
#pod
#pod See L<https://dev.twitter.com/oauth/reference/post/oauth2/token> for details.
#pod
#pod =cut

sub oauth2_token {
    my $self = shift;

    my ( $r, $c ) = $self->request(post => $self->oauth2_url_for('token'), {
        -add_consumer_auth_header => 1,
        grant_type => 'client_credentials',
    });

    # In their wisdom, Twitter sends us a URL encoded token. We need to decode
    # it, so if/when we call invalidate_token, and properly URL encode our
    # parameters, we don't end up with a double-encoded token.
    my $token = url_decode $$r{access_token};
    return wantarray ? ( $token, $c ) : $token;
}

#pod =method invalidate_token($token)
#pod
#pod Calls the C<oauth2/invalidate_token> endpoint to revoke a token. See
#pod L<https://dev.twitter.com/oauth/reference/post/oauth2/invalidate/token> for
#pod details.
#pod
#pod =cut

sub invalidate_token {
    my ( $self, $token ) = @_;

    my ( $r, $c ) = $self->request(
        post =>$self->oauth2_url_for('invalidate_token'), {
            -add_consumer_auth_header => 1,
            access_token              => $token,
    });
    my $token_returned = url_decode $$r{access_token};
    return wantarray ? ( $token_returned, $c ) : $token_returned;
}

# request chain modifiers

around add_authorization => sub {
    shift; # we're overriding the base, so we won't call it
    my ( $self, $c ) = @_;

    my $req = $c->http_request;
    if ( $c->get_option('add_consumer_auth_header') ) {
        $self->$add_consumer_auth_header($req);
    }
    else {
        my $token = $c->get_option('token') // $self->access_token // return;
        $req->header(authorization => join ' ', Bearer => url_encode($token));
    }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Twitter::API::Trait::AppAuth - App-only (OAuth2) Authentication

=head1 VERSION

version 1.0003

=head1 SYNOPSIS

    use Twitter::API;
    my $client = Twitter::API->new_with_traits(
        traits => [ qw/ApiMethods AppAuth/ ]);

    my $r = $client->oauth2_token;
    # return value is hash ref:
    # { token_type => 'bearer', access_token => 'AA...' }
    my $token = $r->{access_token};

    # you can use the token explicitly with the -token argument:
    my $user = $client->show_user('twitter_api', { -token => $token });

    # or you can set the access_token attribute to use it implicitly
    $client->access_token($token);
    my $user = $client->show_user('twitterapi');

    # to revoke a token
    $client->invalidate_token($token);

    # if you revoke the token stored in the access_token attribute, clear it:
    $client->clear_access_token;

=head1 METHODS

=head2 oauth2_token

Call the C<oauth2/token> endpoint to get a bearer token. The token is not
stored in Twitter::API's state. If you want that, set the C<access_token>
attribute with the returned token.

See L<https://dev.twitter.com/oauth/reference/post/oauth2/token> for details.

=head2 invalidate_token($token)

Calls the C<oauth2/invalidate_token> endpoint to revoke a token. See
L<https://dev.twitter.com/oauth/reference/post/oauth2/invalidate/token> for
details.

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2018 by Marc Mims.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
