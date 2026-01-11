package WWW::Hetzner::Cloud::Datacenter;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Datacenter object

our $VERSION = '0.002';

use Moo;
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has id => ( is => 'ro' );


has name => ( is => 'ro' );


has description => ( is => 'ro' );


has location_data => ( is => 'ro', init_arg => 'location', default => sub { {} } );

sub location { shift->location_data->{name} }


sub data {
    my ($self) = @_;
    return {
        id          => $self->id,
        name        => $self->name,
        description => $self->description,
        location    => $self->location_data,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::Datacenter - Hetzner Cloud Datacenter object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $dc = $cloud->datacenters->get_by_name('fsn1-dc14');

    print $dc->name, "\n";        # fsn1-dc14
    print $dc->description, "\n"; # Falkenstein 1 DC14
    print $dc->location, "\n";    # fsn1

=head1 DESCRIPTION

This class represents a Hetzner Cloud datacenter (virtual subdivision of a location).
Objects are returned by L<WWW::Hetzner::Cloud::API::Datacenters> methods.

Datacenters are read-only resources.

=head2 id

Datacenter ID.

=head2 name

Datacenter name, e.g. "fsn1-dc14".

=head2 description

Human-readable description.

=head2 location

Location name (convenience accessor).

=head2 data

    my $hashref = $dc->data;

Returns all datacenter data as a hashref (for JSON serialization).

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
