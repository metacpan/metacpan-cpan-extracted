package WWW::Suffit::Client::V1;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

WWW::Suffit::Client::V1 - The Suffit API client library for V1 methods

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use WWW::Suffit::Client::V1;

=head1 DESCRIPTION

This library provides V1 methods for access to Suffit API servers

=head1 API METHODS

List of predefined the Suffit API methods

=head2 authn

    my $status = $client->authn($username, $password);

Performs user authentication on the OWL system

=head2 authz

    my $status = $client->authz(GET => "https://bob@owl.localhost:8695/stuff");
    my $status = $client->authz(GET => "https://owl.localhost:8695/stuff",
        { # Options
            verbose => \1,
            username => "bob",
            address => "127.0.0.1",
            headers => { # Headers
                Accept => "text/html,text/plain",
                Connection => "keep-alive",
                Host => "owl.localhost:8695",
            },
        },
    );

Performs user authorization on the OWL system

=head2 pubkey

    my $status = $client->pubkey();
    my $status = $client->pubkey(1); # Set public_key to object

Returns RSA public key of the token owner

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

our $VERSION = '1.01';

use parent qw/ WWW::Suffit::Client /;

use WWW::Suffit::Const qw/ :MIME /;
use WWW::Suffit::RSA;

## SUFFIT API V1 METHODS

sub authn {
    my $self = shift;
    my $username = shift;
    my $password = shift;
    my $encrypted = 0;

    if (length($self->public_key)) {
        my $rsa = WWW::Suffit::RSA->new(public_key => $self->public_key);
        $password = $rsa->encrypt($password); # Encrypt password
        if ($rsa->error) {
            $self->error($rsa->error);
            $self->status(0);
            return 0;
        }
        $encrypted = 1;
    }

    my %data = ();
    $data{username} = $username if defined $username;
    $data{password} = $password if defined $password;
    $data{encrypted} = \$encrypted,

    # Request
    return $self->request(POST => $self->str2url("v1/authn"),
        { # Headers
            Accept => CONTENT_TYPE_JSON, # "*/*"
        },
        json => {%data},
    );
}
sub authz {
    my $self = shift;
    my $method = shift // '';
    my $url = shift // '';
    my $options = shift || {};
       $options = {} unless ref($options) eq 'HASH';
    my %data = ();
    $data{method} = $method if length($method);
    $data{url} = $url if length($url);
    $data{username} = $options->{username} if exists $options->{username};
    $data{verbose} = $options->{verbose} if exists $options->{verbose};
    $data{address} = $options->{address} if exists $options->{address};
    my $headers = $options->{headers};
    $data{headers} = $headers if ref($headers) eq 'HASH';

    # Request
    return $self->request(POST => $self->str2url("v1/authz"),
        { # Headers
            Accept => CONTENT_TYPE_JSON, # "*/*"
        },
        json => {%data},
    );
}
sub pubkey {
    my $self = shift;
    my $set = shift || 0;

    # Request
    my $status = $self->request(GET => $self->str2url("v1/publicKey"),
        { # Headers
            Accept => CONTENT_TYPE_JSON, # "*/*"
        },
    );
    return 0 unless $status;

    # Get public_key
    my $public_key = $self->res->json("/public_key") if $self->res->json("/status");
    $self->public_key($public_key) if $set && length($public_key // '');

    return $status;
}

1;

__END__
