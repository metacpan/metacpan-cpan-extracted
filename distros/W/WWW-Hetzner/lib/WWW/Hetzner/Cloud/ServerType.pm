package WWW::Hetzner::Cloud::ServerType;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud ServerType object

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


has cores => ( is => 'ro' );


has memory => ( is => 'ro' );


has disk => ( is => 'ro' );


has cpu_type => ( is => 'ro' );


has architecture => ( is => 'ro' );


has deprecated => ( is => 'ro' );


sub data {
    my ($self) = @_;
    return {
        id           => $self->id,
        name         => $self->name,
        description  => $self->description,
        cores        => $self->cores,
        memory       => $self->memory,
        disk         => $self->disk,
        cpu_type     => $self->cpu_type,
        architecture => $self->architecture,
        deprecated   => $self->deprecated,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::ServerType - Hetzner Cloud ServerType object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $type = $cloud->server_types->get_by_name('cx22');

    print $type->name, "\n";         # cx22
    print $type->cores, "\n";        # 2
    print $type->memory, "\n";       # 4
    print $type->disk, "\n";         # 40
    print $type->architecture, "\n"; # x86

=head1 DESCRIPTION

This class represents a Hetzner Cloud server type (CPU/memory/disk configuration).
Objects are returned by L<WWW::Hetzner::Cloud::API::ServerTypes> methods.

Server types are read-only resources.

=head2 id

Server type ID.

=head2 name

Server type name, e.g. "cx22", "cpx31".

=head2 description

Human-readable description.

=head2 cores

Number of CPU cores.

=head2 memory

Memory in GB.

=head2 disk

Disk size in GB.

=head2 cpu_type

CPU type: shared or dedicated.

=head2 architecture

CPU architecture: x86 or arm.

=head2 deprecated

Deprecation timestamp if deprecated, undef otherwise.

=head2 data

    my $hashref = $type->data;

Returns all server type data as a hashref (for JSON serialization).

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
