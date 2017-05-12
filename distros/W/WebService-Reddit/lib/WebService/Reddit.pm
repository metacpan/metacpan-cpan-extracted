package WebService::Reddit;
$WebService::Reddit::VERSION = '0.000003';
use Moo 2.003000;
use MooX::StrictConstructor;

use Types::Standard qw( Bool InstanceOf Int Str );
use Types::URI -all;
use URI                          ();
use WWW::Mechanize               ();
use WebService::Reddit::Response ();

has access_token => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    writer   => '_set_access_token',
);

has access_token_expiration => (
    is        => 'ro',
    isa       => Int,
    predicate => 'has_access_token_expiration',
    writer    => '_set_access_token_expiration',
);

has _app_key => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'app_key',
    required => 1,
);

has _app_secret => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'app_secret',
    required => 1,
);

has _base_uri => (
    is       => 'ro',
    isa      => Uri,
    init_arg => 'base_uri',
    lazy     => 1,
    coerce   => 1,
    default  => 'https://oauth.reddit.com',
);

has _refresh_token => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'refresh_token',
    required => 1,
    writer   => '_set_token',
);

has ua => (
    is      => 'ro',
    isa     => InstanceOf ['LWP::UserAgent'],
    lazy    => 1,
    default => sub { WWW::Mechanize->new( autocheck => 0 ) },
);

sub get {
    my $self = shift;
    my $uri  = $self->_normalize_uri(@_);

    return $self->_perform_request(
        sub { $self->ua->get( $uri, $self->_auth ) } );
}

sub post {
    my $self = shift;
    my $uri  = $self->_normalize_uri(shift);
    my $form = shift;

    return $self->_perform_request(
        sub { $self->ua->post( $uri, $form, $self->_auth ) } );
}

sub delete {
    my $self = shift;
    my $uri  = $self->_normalize_uri(@_);
    return $self->_perform_request(
        sub { $self->ua->delete( $uri, $self->_auth ) } );
}

sub _auth {
    my $self = shift;
    return ( Authorization => 'bearer ' . $self->access_token );
}

sub _normalize_uri {
    my $self   = shift;
    my $path   = shift;
    my $params = shift;

    my $relative_uri = URI->new($path);
    my $uri          = $self->_base_uri->clone;
    $uri->path( $relative_uri->path );
    $uri->query_form($params) if keys %{$params};

    return $uri;
}

sub _perform_request {
    my $self = shift;
    my $cb   = shift;

    my $res = WebService::Reddit::Response->new( raw => $cb->() );
    if ( $res->code == 401 ) {
        $self->refresh_access_token;
        $res = WebService::Reddit::Response->new( raw => $cb->() );
    }
    return $res;
}

sub refresh_access_token {
    my $self = shift;
    $self->ua->credentials( $self->_app_key, $self->_app_secret );
    my $res = WebService::Reddit::Response->new(
        raw => $self->ua->post(
            'https://www.reddit.com/api/v1/access_token',
            {
                grant_type    => 'refresh_token',
                refresh_token => $self->_refresh_token
            }
        )
    );

    my $auth = $res->content;
    die 'Cannot refresh token: ' . $res->as_string unless $res->success;

    $self->_set_access_token( $auth->{access_token} );
    $self->_set_access_token_expiration( time + $auth->{expires_in} );
    $self->ua->clear_credentials;

    return 1;
}

1;

# ABSTRACT: Thin wrapper around the Reddit OAuth API

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Reddit - Thin wrapper around the Reddit OAuth API

=head1 VERSION

version 0.000003

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WebService::Reddit ();

    my $client = WebService::Reddit->new(
        access_token  => 'secret-access-token',
        app_key       => 'my-app-id',
        app_secret    => 'my-app-secret',
        refresh_token => 'secret-refresh-token',
    );

    my $me = $client->get('/api/v1/me');

    # Dump HashRef of response
    use Data::Printer;
    p( $me->content );

=head1 DESCRIPTION

beta beta beta.  Interface is subject to change.

This is a very thin wrapper around the Reddit OAuth API.

=head1 CONSTRUCTOR AND STARTUP

=head2 new

=over 4

=item * C<< access_token >>

A (once) valid OAuth access token.  It's ok if it has expired.

=item * C<< app_key >>

The key which Reddit has assigned to your app.

=item * C<< app_secret >>

The secret which Reddit has assigned to your app.

=item * C<< refresh_token >>

A valid C<refresh_token> which the Reddit API has provided.

=item * C<< ua >>

Optional.  A useragent of the L<LWP::UserAgent> family.

=item * C<< base_uri >>

Optional.  Provide only if you want to route your requests somewhere other than
the Reddit OAuth endpoint.

=back

=head2 get

Accepts a relative URL path and an optional HashRef of params.  Returns a
L<WebService::Reddit::Response> object.

    my $me = $client->get('/api/v1/me');
    my $new_posts = $client->get( '/r/perl/new', { limit => 25 } );

=head2 delete

Accepts a relative URL path and an optional HashRef of params.  Returns a
L<WebService::Reddit::Response> object.

    my $delete = $client->delete(
        '/api/v1/me/friends/randomusername',
        { id => 'someid' }
    );

=head2 post

Accepts a relative URL path and an optional HashRef of params.  Returns a
L<WebService::Reddit::Response> object.

    my $post = $reddit->post(
        '/api/search_reddit_names',
        { exact => 1, query => 'perl' }
    );

=head2 access_token

Returns the current C<access_token>.  This may not be the token which you
originally supplied.  If your supplied token has been expired, then this module
will try to get you a fresh C<access_token>.

=head2 access_token_expiration

Returns expiration time of access token in epoch seconds, if available.  Check
the predicate before calling this method in order to avoid a possible
exception.

    print $client->access_token_expiration
        if $client->has_access_token_expiration .

=head2 has_access_token_expiration

Predicate.  Returns true if C<access_token_expiration> has been set.

=head2 refresh_access_token

Tries to refresh the C<access_token>.  Returns true on success and dies on
failure.  Use the C<access_token> method to get the new token if this method
has returned C<true>.

=head2 ua

Returns the UserAgent which is being used to make requests.  Defaults to a
L<WWW::Mechanize> object.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
