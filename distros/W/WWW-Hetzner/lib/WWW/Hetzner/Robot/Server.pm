package WWW::Hetzner::Robot::Server;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Robot Server entity

our $VERSION = '0.002';

use Moo;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has server_number => ( is => 'ro', required => 1 );


has server_name   => ( is => 'rw' );


has server_ip     => ( is => 'ro' );


has product       => ( is => 'ro' );


has dc            => ( is => 'ro' );


has traffic       => ( is => 'ro' );


has status        => ( is => 'ro' );


has cancelled     => ( is => 'ro' );


has paid_until    => ( is => 'ro' );


# Convenience accessors
sub id   { shift->server_number }


sub name { shift->server_name }


sub ip   { shift->server_ip }


sub reset {
    my ($self, $type) = @_;
    $type //= 'sw';
    return $self->client->post("/reset/" . $self->server_number, { type => $type });
}


sub update {
    my ($self) = @_;
    return $self->client->post("/server/" . $self->server_number, {
        server_name => $self->server_name,
    });
}


sub refresh {
    my ($self) = @_;
    my $data = $self->client->get("/server/" . $self->server_number);
    my $server = $data->{server};
    for my $key (keys %$server) {
        my $attr = $key;
        if ($self->can($attr)) {
            $self->{$attr} = $server->{$key};
        }
    }
    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::Server - Hetzner Robot Server entity

=head1 VERSION

version 0.002

=head2 server_number

Unique server ID.

=head2 server_name

Server name.

=head2 server_ip

Primary IP address.

=head2 product

Server product type.

=head2 dc

Datacenter.

=head2 traffic

Traffic limit.

=head2 status

Server status (ready, in process).

=head2 cancelled

Cancellation status.

=head2 paid_until

Paid until date.

=head2 id

Convenience accessor for C<server_number>.

=head2 name

Convenience accessor for C<server_name>.

=head2 ip

Convenience accessor for C<server_ip>.

=head2 reset

    $server->reset('sw');  # software reset
    $server->reset('hw');  # hardware reset

=head2 update

    $server->server_name('new-name');
    $server->update;

=head2 refresh

    $server->refresh;  # reload from API

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
