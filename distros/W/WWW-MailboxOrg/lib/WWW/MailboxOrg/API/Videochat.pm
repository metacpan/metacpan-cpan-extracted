package WWW::MailboxOrg::API::Videochat;

# ABSTRACT: Video chat API

use Moo;
use MooX::Singleton;
use Carp qw(croak);
use Params::ValidationCompiler qw(validation_for);
use Types::Standard qw(Str);

our $VERSION = '0.001';

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _rpc {
    my ($self, $method, @params) = @_;
    my $client = $self->client or croak "No client set";
    return $client->call($method, @params);
}

my %validators = (
    status => validation_for(
        params => {
            account => { type => Str, optional => 0 },
        },
    ),
    create_room => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            name    => { type => Str, optional => 0 },
        },
    ),
    list_rooms => validation_for(
        params => {
            account => { type => Str, optional => 0 },
        },
    ),
    delete_room => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            name    => { type => Str, optional => 0 },
        },
    ),
);

sub status {
    my ($self, %params) = @_;
    my $v = $validators{'status'};
    %params = $v->(%params) if $v;
    return $self->_rpc('videochat.status', \%params);
}

sub create_room {
    my ($self, %params) = @_;
    my $v = $validators{'create_room'};
    %params = $v->(%params) if $v;
    return $self->_rpc('videochat.create_room', \%params);
}

sub list_rooms {
    my ($self, %params) = @_;
    my $v = $validators{'list_rooms'};
    %params = $v->(%params) if $v;
    return $self->_rpc('videochat.list_rooms', \%params);
}

sub delete_room {
    my ($self, %params) = @_;
    my $v = $validators{'delete_room'};
    %params = $v->(%params) if $v;
    return $self->_rpc('videochat.delete_room', \%params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::Videochat - Video chat API

=head1 VERSION

version 0.001

=head1 NAME

WWW::MailboxOrg::API::Videochat - Video chat API

=head2 status

    my $status = $api->videochat->status(account => 'admin@example.com');

Get video chat status. Required: C<account>.

=head2 create_room

    $api->videochat->create_room(
        account => 'admin@example.com',
        name    => 'My Room',
    );

Create a video chat room. Required: C<account>, C<name>.

=head2 list_rooms

    $api->videochat->list_rooms(account => 'admin@example.com');

List video chat rooms. Required: C<account>.

=head2 delete_room

    $api->videochat->delete_room(
        account => 'admin@example.com',
        name    => 'My Room',
    );

Delete a video chat room. Required: C<account>, C<name>.

=cut

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/getty/p5-www-mailboxorg/issues>.

=head2 IRC

Join C<#perl-help> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
