package WWW::Hetzner::Cloud::PlacementGroup;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Placement Group object

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has id => ( is => 'ro' );


has name => ( is => 'rw' );


has type => ( is => 'ro' );


has servers => ( is => 'ro', default => sub { [] } );


has labels => ( is => 'rw', default => sub { {} } );


has created => ( is => 'ro' );


# Actions
sub update {
    my ($self) = @_;
    croak "Cannot update placement group without ID" unless $self->id;

    $self->_client->put("/placement_groups/" . $self->id, {
        name   => $self->name,
        labels => $self->labels,
    });
    return $self;
}


sub delete {
    my ($self) = @_;
    croak "Cannot delete placement group without ID" unless $self->id;

    $self->_client->delete("/placement_groups/" . $self->id);
    return 1;
}


sub data {
    my ($self) = @_;
    return {
        id      => $self->id,
        name    => $self->name,
        type    => $self->type,
        servers => $self->servers,
        labels  => $self->labels,
        created => $self->created,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::PlacementGroup - Hetzner Cloud Placement Group object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $pg = $cloud->placement_groups->get($id);

    print $pg->name, "\n";
    print $pg->type, "\n";  # spread
    print scalar(@{$pg->servers}), " servers\n";

    # Update
    $pg->name('new-name');
    $pg->update;

    # Delete
    $pg->delete;

=head1 DESCRIPTION

This class represents a Hetzner Cloud placement group. Objects are returned by
L<WWW::Hetzner::Cloud::API::PlacementGroups> methods.

=head2 id

Placement group ID (read-only).

=head2 name

Placement group name (read-write).

=head2 type

Placement group type, e.g. "spread" (read-only).

=head2 servers

Arrayref of server IDs in this placement group (read-only).

=head2 labels

Labels hash (read-write).

=head2 created

Creation timestamp (read-only).

=head2 update

    $pg->name('new-name');
    $pg->update;

Saves changes to name and labels.

=head2 delete

    $pg->delete;

Deletes the placement group.

=head2 data

    my $hashref = $pg->data;

Returns all placement group data as a hashref (for JSON serialization).

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
