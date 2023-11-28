use strict;
use warnings;

use v5.010;

package WebService::Readwise;

# ABSTRACT: Perl module to interact with Readwise.io API
use HTTP::Tiny;
use JSON::MaybeXS;

use Moo;
use namespace::clean;


has token => (
    is       => 'ro',
    required => 0,
    default  => sub { return $ENV{WEBSERVICE_READWISE_TOKEN} },
);


has base_url => (
    is      => 'ro',
    default => sub {'https://readwise.io/api/v2/'},
);


has http => (
    is      => 'ro',
    default => sub {
        return HTTP::Tiny->new;
    },
);


sub auth {
    my $self = shift;

    my $response = $self->http->request(
        'GET',
        $self->base_url . 'auth/',
        { headers => { Authorization => "Token $self->{token}", }, }
    );

    return $response->{status};
}


sub export {
    my ( $self, %params ) = @_;

    my $path = 'export/';
    if ( %params && $params{'pageCursor'} ) {
        $path .= '?pageCursor=' . $params{pageCursor};
    }

    my $response = $self->http->request(
        'GET',
        $self->base_url . $path,
        { headers => { Authorization => "Token $self->{token}", }, }
    );

    if ( !$response->{success} ) {
        return 'Response error';
    }

    my $json = decode_json $response->{content};

    return $json;
}


sub highlights {
    my $self = shift;

    my $response = $self->http->request(
        'GET',
        $self->base_url . 'highlights/',
        { headers => { Authorization => "Token $self->{token}", }, }
    );

    if ( !$response->{success} ) {
        return 'Response error';
    }

    my $json = decode_json $response->{content};

    return $json;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Readwise - Perl module to interact with Readwise.io API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WebService::Readwise;
    my $readwise = WebService::Readwise->new(token => 'readwise_token_foo');
    my $highlights = $readwise->highlights;
    say 'First highlight: ' . $highlights->{results}[0]{text};

=head1 DESCRIPTION

Access the L<https://readwise.io/api_deets> API.

=head1 ATTRIBUTES

=head2 token( $token )

API token from readwise.io.

Obtain thihs from L<https://readwise.io/access_token>

If not provided can be obtained from WEBSERVICE_READWISE_TOKEN environment variable

=head2 base_url( $url )

URL for the Readwise API.

Defaults if not specified

=head2 http( )

Provides L<HTTP::Tiny> object. Used to get data from API.

=head1 METHODS

=head2 auth( )

Returns 204 if you have a valid token

Makes a GET request to https://readwise.io/api/v2/auth/

=head2 export( pageCursor => $cursor)

Returns data structure containing a paginated record of all your Readwise data.

Optionally,the pageCursor parameter can be used to retrieve additionalpages of results

Makes a GET request to https://readwise.io/api/v2/export/

=head2 highlights( )

Returns array of highlights

Makes a GET request to https://readwise.io/api/v2/highlight/

=head1 AUTHOR

Lance Wicks <lw@judocoach.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Lance Wicks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
