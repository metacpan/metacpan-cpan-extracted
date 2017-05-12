package Vero::API;
use version; our $VERSION = version->declare("v0.1.2");
use 5.010;
use Carp;
use failures qw/vero::api/;
use Mojo::UserAgent;
use Mojo::JSON 'j';
use Moo;
use namespace::autoclean;

has ua => (
    is      => 'rw',
    builder => 1,
);
sub _build_ua {
    my $ua      = Mojo::UserAgent->new;
    my $agentid = "Vero::API/$VERSION (Perl)";
    # $ua->name was deprecated on Mojolicious 4.50
    $ua->transactor->can('name') ? $ua->transactor->name($agentid) : $ua->name($agentid);
    return $ua;
}

has token => (
    is      => 'rw',
    builder => 1,
);

sub _build_token {
    croak 'A token is required during initialization. Pass one on constructor or override "_build_token" to return one';
}

sub identify_user {
    my ($self, %info) = @_;
    my $id    = delete $info{id};
    my $email = delete $info{email};

    croak 'id or email is required' unless defined $id or defined $email;

    my $tx = $self->ua->post(
        'https://api.getvero.com/api/v2/users/track.json',
        json => {
            auth_token => $self->token,
            ($id    ? (id    => $id)    : ()),
            ($email ? (email => $email) : ()),
            data => {%info},
        });
    unless ($tx->success) {
        my ($err, $code) = $tx->error;
        failure::vero::api->throw("Vero API returned error: code $code, error $err, data " . j($tx->res->json));
    }
    return $tx->res->json;
}

sub track_event {
    my ($self, $event_name, %info) = @_;
    my $id    = delete $info{id};
    my $email = delete $info{email};

    croak 'id or email is required' unless defined $id or defined $email;

    my $tx = $self->ua->post(
        'https://api.getvero.com/api/v2/events/track.json',
        json => {
            auth_token => $self->token,
            'identity' => {
                ($id    ? (id    => $id)    : ()),
                ($email ? (email => $email) : ()),
            },
            event_name => $event_name,
            data       => {%info},
        });
    unless ($tx->success) {
        my ($err, $code) = $tx->error;
        failure::vero::api->throw("Vero API returned error: code $code, error $err, data " . j($tx->res->json));
    }
    return $tx->res->json;
}

1;

__END__

=head1 NAME

Vero::API - Perl interface to the Vero API.

=head1 SYNOPSIS

    use Vero::API;

    my $vero = Vero::API->new( token => 'your-secret-auth-token' );

    $vero->identify_user(
        id      => 'BR0001',
        email   => 'zezinho@example.com',
        name    => 'Jose da Silva',
        country => 'br',
    );

    $vero->track_event(
        'favorited-item',
        id      => 'BR0001',
        item_id => 'bicicleta laranja',
    );


=head1 DESCRIPTION

A quick and simple perl interface to L<Vero|https://www.getvero.com> API.

C<Vero::API> uses L<Mojo::UserAgent> for talking to the Vero API
using L<Mojo::JSON>.

Response is parsed back from JSON and returned as perl data structure.

=head1 METHODS

=over 4

=item C<< new(token => 'your-auth-token') >>

Constructs a new C<Vero::API> object storing your C<token>.

=item C<token>

Returns the stored token.

=item C<< identify_user(id => 'clientid', email => 'client@example.com', %extra_info) >>

Calls the API to register/update a user record.

=item C<< track_event($event_name, [id => $clientid,] [email => $email], %extra_info) >>

Calls the API to register an event for that user.

You can pass either one of id, email or both.
Extra info passed in as a hash will be available to use on email templates triggered by that event.

Example:

    $vero->track_event('bought-item', id => 'BR0001', item => 'Clock', price => '1.00');

=back

=head1 STATUS

=begin html

<p><a href="https://travis-ci.org/carloslima/vero-api-pm"><img src="https://travis-ci.org/carloslima/vero-api-pm.png?branch=master" alt="Build Status" style="max-width:100%;"></a></p>

=end html

=head1 SEE ALSO

L<verocli>

=head1 AUTHOR

Carlos Lima <carlos@cpan.org>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Carlos Lima <carlos@cpan.org>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
