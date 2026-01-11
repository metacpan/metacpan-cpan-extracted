package WWW::Hetzner::Robot::API::Reset;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Robot Server Reset API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub get {
    my ($self, $server_number) = @_;
    croak "Server number required" unless $server_number;
    my $result = $self->client->get("/reset/$server_number");
    return $result->{reset};
}


sub execute {
    my ($self, $server_number, $type) = @_;
    croak "Server number required" unless $server_number;
    $type //= 'sw';
    croak "Invalid reset type: $type (must be sw, hw, or man)"
        unless $type =~ /^(sw|hw|man)$/;

    my $result = $self->client->post("/reset/$server_number", { type => $type });
    return $result->{reset};
}


sub software {
    my ($self, $server_number) = @_;
    return $self->execute($server_number, 'sw');
}


sub hardware {
    my ($self, $server_number) = @_;
    return $self->execute($server_number, 'hw');
}


sub manual {
    my ($self, $server_number) = @_;
    return $self->execute($server_number, 'man');
}


sub wol {
    my ($self, $server_number) = @_;
    croak "Server number required" unless $server_number;
    my $result = $self->client->post("/wol/$server_number", {});
    return $result->{wol};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::API::Reset - Hetzner Robot Server Reset API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $robot = WWW::Hetzner::Robot->new(...);

    # Check reset options
    my $reset_info = $robot->reset->get(123456);

    # Execute reset
    $robot->reset->execute(123456, 'sw');   # software reset
    $robot->reset->execute(123456, 'hw');   # hardware reset
    $robot->reset->execute(123456, 'man');  # manual reset

    # Convenience methods
    $robot->reset->software(123456);
    $robot->reset->hardware(123456);
    $robot->reset->manual(123456);

    # Wake-on-LAN
    $robot->reset->wol(123456);

=head1 DESCRIPTION

Reset types:

=over 4

=item * B<sw> - Software reset (CTRL+ALT+DEL)

=item * B<hw> - Hardware reset (power cycle)

=item * B<man> - Manual reset (technician intervention)

=back

=head2 get

    my $info = $robot->reset->get($server_number);

Returns available reset options.

=head2 execute

    $robot->reset->execute($server_number, $type);

Execute reset of specified type.

=head2 software

Convenience method for software reset.

=head2 hardware

Convenience method for hardware reset.

=head2 manual

Convenience method for manual reset.

=head2 wol

    $robot->reset->wol($server_number);

Send Wake-on-LAN packet.

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
