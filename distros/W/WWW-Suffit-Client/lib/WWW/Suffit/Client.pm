package WWW::Suffit::Client;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

WWW::Suffit::Client - The Suffit API client library

=head1 SYNOPSIS

    use WWW::Suffit::Client;

    my $clinet = WWW::Suffit::Client->new(
        url                 => "https://localhost",
        username            => "username", # optional
        password            => "password", # optional
        max_redirects       => 2, # Default: 10
        connect_timeout     => 3, # Default: 10 sec
        inactivity_timeout  => 5, # Default: 30 sec
        request_timeout     => 10, # Default: 5 min (300 sec)
    );
    my $status = $client->check();

    if ($status) {
        print STDOUT $client->res->body;
    } else {
        print STDERR $clinet->error;
    }

=head1 DESCRIPTION

This library provides methods for access to Suffit API servers

=head1 METHODS

List of extended API methods

=head2 apierr

    die $client->apierr;

This method returns the value of the "/message" API parameter or a client error if no message found.
Otherwise, this method returns a string containing an HTTP error message

=head1 API METHODS

List of predefined the Suffit API methods

=head2 api_check

    my $status = $client->api_check;
    my $status = $client->api_check( URLorPath );

Returns API check-status. 0 - Error; 1 - Ok

=head2 api_data

    my $status = $client->api_data;
    my $status = $client->api_data( URLorPath );

Gets API data

=head2 api_token

    my $status = $client->api_token;

Gets API token

=head2 authorize

    my $status = $client->authorize($username, $password, {
        encrypted => \0,
        foo => \1,
    });

Performs authorization on the server and returns access token.
This is private method!

=head1 DEPENDENCIES

L<Mojolicious>, L<WWW::Suffit>

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojo::UserAgent>, L<WWW::Suffit::UserAgent>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.02';

use parent qw/ WWW::Suffit::UserAgent /;

use WWW::Suffit::Const qw/ :MIME /;

## SUFFIT API COMMON METHODS

sub apierr {
    my $self = shift;
    return $self->res->json("/message") || $self->error || $self->res->message
};

sub api_check {
    my $self = shift;
    my $url = shift || 'check'; # URL or String (e.g.: api/check)
    my $status = $self->request(GET => $self->str2url($url),
        { # Headers
            Accept => CONTENT_TYPE_JSON, # "*/*"
        }
    );
    return 0 unless $status;

    # Check API status
    return 0 unless $self->res->json("/status");

    # Check code
    my $error_code = $self->res->json("/code") || 'E0000';
    return 0 unless $error_code eq 'E0000';

    return $status;
}
sub api_data {
    my $self = shift;
    my $url = shift || ''; # URL or String (e.g.: api)
    return $self->request(GET => $self->str2url($url),
        { # Headers
            Accept => CONTENT_TYPE_JSON, # "*/*"
        }
    );
}
sub api_token {
    my $self = shift;
    return $self->request(POST => $self->str2url("user/token"), # e.g.: api/user/token
        { # Headers
            Accept => CONTENT_TYPE_JSON, # "*/*"
        }
    );
}
sub authorize { # System authorization, NO USER PUBLIC method!
    my $self = shift;
    my $username = shift;
    my $password = shift;
    my $options = shift || {};
       $options = {} unless ref $options eq 'HASH';
    $options->{username} = $username if defined $username;
    $options->{password} = $password if defined $password;

    return $self->request(POST => $self->str2url("/authorize"),
        { # Headers
            Accept => CONTENT_TYPE_JSON, # "*/*"
        },
        json => $options,
    );
}

1;

__END__
