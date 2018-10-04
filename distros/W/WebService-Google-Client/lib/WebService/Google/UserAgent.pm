package WebService::Google::UserAgent;
our $VERSION = '0.06';

# ABSTRACT: User Agent wrapper for working with Google APIs

use Moo;
use WebService::Google::Client::Credentials;
use WebService::Google::Client::AuthStorage;
use Log::Log4perl::Shortcuts qw(:all);
use Mojo::UserAgent;
use Data::Dumper;     # for debug
use Data::Printer;    # for debug

has 'ua' => ( is => 'ro', default => sub { Mojo::UserAgent->new } );
has 'do_autorefresh' => ( is => 'rw', default => 1 )
  ;                   # if 1 storage must be configured
has 'auto_update_tokens_in_storage' => ( is => 'rw', default => 1 );
has 'credentials' => (
    is      => 'rw',
    default => sub { WebService::Google::Client::Credentials->instance },
    handles => [qw(access_token user auth_storage)],
    lazy    => 1
);

# Keep access_token in headers always actual

sub build_headers {

    # warn "".(caller(0))[3]."() : ".Dumper \@_;
    my $self = shift;

    # p $self;
    my $headers = {};

    # warn "build_headers: ".$self->access_token;
    if ( $self->access_token ) {
        $headers->{'Authorization'} = 'Bearer ' . $self->access_token;
        return $headers;
    }
    else {
        die 'No access_token, cant build headers';
    }

}


sub build_http_transaction {
    my ( $self, $params ) = @_;

    # warn "".(caller(0))[3]."() : ".Dumper \@_;

    my $headers = $self->build_headers;

    #    warn "build_http_transaction HEADERS: " . Dumper $headers
    #      if ( $self->debug );

    # Hash key names
    my $http_method   = $params->{httpMethod};    # uppercase
    my $path          = $params->{path};
    my $optional_data = $params->{options};

    #    warn "build_http_transaction() Options: " . Dumper $optional_data
    #      if ( $self->debug );

    my $tx;

    if ( !defined $http_method ) { die 'No http method specified' }

    if ( ( $http_method eq uc 'post' ) && !defined $optional_data ) {
        warn 'Attention! You are using POST, but no payload specified';
    }

    if ( lc $http_method eq 'get' ) {
        $tx = $self->ua->build_tx(
            uc $http_method => $path => $headers => form => $optional_data );
    }
    elsif ( lc $http_method eq 'delete' ) {
        $tx = $self->ua->build_tx( uc $http_method => $path => $headers );
    }
    elsif (
        (
               ( lc $http_method eq 'post' )
            || ( lc $http_method eq 'patch' )
            || ( lc $http_method eq 'put' )
        )
        && ( defined $optional_data )
      )
    {
        $tx = $self->ua->build_tx(
            uc $http_method => $path => $headers => json => $optional_data );
    }
    elsif (
        (
               ( lc $http_method eq 'post' )
            || ( lc $http_method eq 'patch' )
            || ( lc $http_method eq 'put' )
        )
        && ( !defined $optional_data )
      )
    {
        $tx = $self->ua->build_tx( uc $http_method => $path => $headers );
    }

    return $tx;

}


sub api_query {
    my ( $self, $params ) = @_;

    # warn "".(caller(0))[3]."() : ".Dumper \@_ if $self->debug;

    my $tx = $self->build_http_transaction($params);

    # warn Dumper $tx;
    # warn "transaction built ok";

    my $res = $self->ua->start($tx)->res;

    # In case if access_token expired
    # warn $response->message; # Unauthorized
    # warn $response->json->{error}{message}; # Invalid Credentials
    # warn $response->code; # 401
    # warn $response->is_error; # 1

    # my $res = $self->ua->start($tx)->res->json;  # Mojo::Message::Response

# for future:
# if ( grep { $_->{message} eq 'Invalid Credentials' && $_->{reason} eq 'authError'} @{$res->{error}{errors}} ) { ... }

    # warn "First api_query() result : ".Dumper $res if $self->debug;
    # warn "Auto refresh:".$self->do_autorefresh;

# if ((defined $res->{error}) && ($self->autorefresh) && ($self->auth_storage->type) && ($self->auth_storage->path)) { # token expired error handling

    # https://metacpan.org/pod/Mojo::Message::Response#code

    # if ((defined $res->{error}) && ($self->do_autorefresh)) {

    if ( ( $res->code == 401 ) && $self->do_autorefresh ) {

        my $attempt = 1;

        #while ($res->{error}{message} eq 'Invalid Credentials')  {
        while ( $res->code == 401 ) {

            warn
"Seems like access_token was expired. Attemptimg update it automatically ...";

# warn "Seems like access_token was expired. Attemptimg update it automatically ..." if $self->debug;

            if ( !$self->user ) {
                die
"No user specified, so cant find refresh token and update access_token";
            }

            my $cred =
              $self->auth_storage->get_credentials_for_refresh( $self->user )
              ;    # get client_id, client_secret and refresh_token
            my $new_token = $self->refresh_access_token($cred)->{access_token}
              ;    # here also {id_token} etc

            #            warn "Got a new token: " . $new_token if $self->debug;
            $self->access_token($new_token);

            if ( $self->auto_update_tokens_in_storage ) {
                $self->auth_storage->set_access_token_to_storage( $self->user,
                    $self->access_token );
            }

            $tx = $self->build_http_transaction($params);
            $res = $self->ua->start($tx)->res;    # Mojo::Message::Response
        }

    }

    return $res;                                  # Mojo::Message::Response
}


sub refresh_access_token {
    my ( $self, $credentials ) = @_;

    if (   ( !defined $credentials->{client_id} )
        || ( !defined $credentials->{client_secret} )
        || ( !defined $credentials->{refresh_token} ) )
    {
        die
"Not enough credentials to refresh access_token. Check that you provided client_id, client_secret and refresh_token";
    }

 #    warn "Attempt to refresh access_token with params: " . Dumper $credentials
 #      if $self->debug;
    $credentials->{grant_type} = 'refresh_token';
    $self->ua->post(
        'https://www.googleapis.com/oauth2/v4/token' => form => $credentials )
      ->res->json;    # tokens
}

1;

__END__

=pod

=head1 NAME

WebService::Google::UserAgent - User Agent wrapper for working with Google APIs

=head1 VERSION

version 0.06

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
