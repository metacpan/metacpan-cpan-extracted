package Zapp::Task::GetOAuth2Token;
# ABSTRACT: Get an OAuth2 Token

#pod =head1 DESCRIPTION
#pod
#pod This task gets an OAuth2 token from the given provider.
#pod
#pod =head2 Output
#pod
#pod     access_token        - The access token
#pod     token_type          - The type of token. Only Bearer tokens are available so far.
#pod     scope               - The scopes returned
#pod     expires_in
#pod     refresh_token
#pod
#pod =head1 SEE ALSO
#pod
#pod =cut

use Mojo::Base 'Zapp::Task', -signatures;
use Mojo::JSON qw( false true );
use Mojo::Util qw( b64_encode );

sub schema( $class ) {
    return {
        input => {
            type => 'object',
            required => [qw( endpoint client_id client_secret )],
            properties => {
                endpoint => {
                    type => 'string',
                },
                client_id => {
                    type => 'string',
                },
                client_secret => {
                    type => 'string',
                },
                scope => {
                    type => 'string',
                },
            },
            additionalProperties => false,
        },
        output => {
            type => 'object',
            required => [qw( access_token token_type )],
            properties => {
                is_success => {
                    type => 'boolean',
                },
                # XXX: Add more validation here? Should invalid results
                # be accepted but flagged? Should users be able to fail
                # invalid results?
                access_token => {
                    type => 'string',
                },
                token_type => {
                    # We only understand Bearer tokens for now.
                    # https://tools.ietf.org/html/rfc6749#section-7.1
                    type => 'string',
                    enum => [qw( bearer )],
                },
                expires_in => {
                    type => 'integer',
                },
                refresh_token => {
                    type => 'string',
                },
                scope => {
                    type => 'string',
                },
            },
        },
    };
}

sub run( $self, $input ) {
    # An OAuth2 client credentials request is authenticated with HTTP
    # basic auth: The client_id is the username, the client_secret is
    # the password. https://tools.ietf.org/html/rfc6749#section-4.4
    my $url = Mojo::URL->new( $input->{endpoint} );
    my $auth = b64_encode( join( ':', $input->@{qw( client_id client_secret )} ), "" );
    my $tx = $self->app->ua->post(
        $url,
        {
            Authorization => 'Basic ' . $auth,
        },
        form => {
            grant_type => 'client_credentials',
            scope => $input->{ scope },
        },
    );

    # The response will be a JSON document. On success (200 OK) it will contain
    # the token. On failure (400 Bad Request) it will describe the
    # error.
    my $json = $tx->res->json;
    my %output = (
        is_success => $tx->res->is_success ? true : false,
    );
    # Success: https://tools.ietf.org/html/rfc6749#section-5.1
    if ( $output{is_success} ) {
        return $self->finish({
            %output,
            $json->%{qw( access_token token_type expires_in refresh_token )},
            # If scope is omitted, it is the same as the scope sent with the
            # request (https://tools.ietf.org/html/rfc6749#section-5.1)
            scope => $json->{scope} || $input->{scope},
        });
    }
    # Error: https://tools.ietf.org/html/rfc6749#section-5.2
    return $self->fail({
        %output,
        $json->%{qw( error error_description error_uri )},
    });
}

1;

=pod

=head1 NAME

Zapp::Task::GetOAuth2Token - Get an OAuth2 Token

=head1 VERSION

version 0.004

=head1 DESCRIPTION

This task gets an OAuth2 token from the given provider.

=head2 Output

    access_token        - The access token
    token_type          - The type of token. Only Bearer tokens are available so far.
    scope               - The scopes returned
    expires_in
    refresh_token

=head1 SEE ALSO

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ input.html.ep
% my $input = stash( 'input' ) // {};
<!-- XXX: A form this simple should be auto-generated from the schema -->
<div class="form-group">
    <label for="endpoint">Endpoint</label>
    %= url_field 'endpoint', value => $input->{endpoint}, class => 'form-control'
</div>
<div class="form-group">
    <label for="client_id">Client ID</label>
    %= text_field 'client_id', value => $input->{client_id}, class => 'form-control'
</div>
<div class="form-group">
    <label for="client_secret">Client Secret</label>
    %= text_field 'client_secret', value => $input->{client_secret}, class => 'form-control'
</div>
<div class="form-group">
    <label for="scope">Scope</label>
    %= text_field 'scope', value => $input->{scope}, class => 'form-control'
</div>

