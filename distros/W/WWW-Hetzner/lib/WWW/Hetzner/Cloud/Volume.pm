package WWW::Hetzner::Cloud::Volume;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Volume object

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


has status => ( is => 'rwp' );


has size => ( is => 'ro' );


has server => ( is => 'ro' );


has created => ( is => 'ro' );


has labels => ( is => 'rw', default => sub { {} } );


has linux_device => ( is => 'ro' );


has format => ( is => 'ro' );


has protection => ( is => 'ro', default => sub { {} } );


# Nested data
has location_data => ( is => 'ro', init_arg => 'location', default => sub { {} } );

# Convenience accessors
sub location { shift->location_data->{name} }


sub is_attached { defined shift->server }


# Actions
sub update {
    my ($self) = @_;
    croak "Cannot update volume without ID" unless $self->id;

    my $result = $self->_client->put("/volumes/" . $self->id, {
        name   => $self->name,
        labels => $self->labels,
    });
    return $self;
}


sub delete {
    my ($self) = @_;
    croak "Cannot delete volume without ID" unless $self->id;

    $self->_client->delete("/volumes/" . $self->id);
    return 1;
}


sub attach {
    my ($self, $server_id, %opts) = @_;
    croak "Cannot attach volume without ID" unless $self->id;
    croak "Server ID required" unless $server_id;

    my $body = { server => $server_id };
    $body->{automount} = $opts{automount} ? \1 : \0 if exists $opts{automount};

    $self->_client->post("/volumes/" . $self->id . "/actions/attach", $body);
    return $self;
}


sub detach {
    my ($self) = @_;
    croak "Cannot detach volume without ID" unless $self->id;

    $self->_client->post("/volumes/" . $self->id . "/actions/detach", {});
    return $self;
}


sub resize {
    my ($self, $size) = @_;
    croak "Cannot resize volume without ID" unless $self->id;
    croak "Size required" unless $size;

    $self->_client->post("/volumes/" . $self->id . "/actions/resize", { size => $size });
    return $self;
}


sub refresh {
    my ($self) = @_;
    croak "Cannot refresh volume without ID" unless $self->id;

    my $result = $self->_client->get("/volumes/" . $self->id);
    my $data = $result->{volume};

    $self->_set_status($data->{status});
    $self->name($data->{name});
    $self->labels($data->{labels} // {});

    return $self;
}


sub data {
    my ($self) = @_;
    return {
        id           => $self->id,
        name         => $self->name,
        status       => $self->status,
        size         => $self->size,
        server       => $self->server,
        created      => $self->created,
        labels       => $self->labels,
        linux_device => $self->linux_device,
        format       => $self->format,
        protection   => $self->protection,
        location     => $self->location_data,
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::Volume - Hetzner Cloud Volume object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $volume = $cloud->volumes->get($id);

    # Read attributes
    print $volume->id, "\n";
    print $volume->name, "\n";
    print $volume->size, " GB\n";
    print $volume->linux_device, "\n";

    # Attach to server
    $volume->attach($server_id);
    $volume->detach;

    # Resize
    $volume->resize(100);  # 100 GB

    # Update
    $volume->name('new-name');
    $volume->update;

    # Delete
    $volume->delete;

=head1 DESCRIPTION

This class represents a Hetzner Cloud volume. Objects are returned by
L<WWW::Hetzner::Cloud::API::Volumes> methods.

=head2 id

Volume ID (read-only).

=head2 name

Volume name (read-write).

=head2 status

Volume status (read-only).

=head2 size

Volume size in GB (read-only).

=head2 server

Attached server ID, or undef if not attached (read-only).

=head2 created

Creation timestamp (read-only).

=head2 labels

Labels hash (read-write).

=head2 linux_device

Linux device path, e.g. "/dev/disk/by-id/scsi-0HC_Volume_123" (read-only).

=head2 format

Filesystem format, e.g. "ext4" (read-only).

=head2 protection

Protection settings hash (read-only).

=head2 location

Location name (convenience accessor).

=head2 is_attached

Returns true if volume is attached to a server.

=head2 update

    $volume->name('new-name');
    $volume->update;

Saves changes to name and labels.

=head2 delete

    $volume->delete;

Deletes the volume.

=head2 attach

    $volume->attach($server_id);
    $volume->attach($server_id, automount => 1);

Attaches volume to a server. Options: automount => 1.

=head2 detach

    $volume->detach;

Detaches volume from server.

=head2 resize

    $volume->resize(100);  # 100 GB

Resizes volume to new size in GB. Can only increase size.

=head2 refresh

    $volume->refresh;

Reloads volume data from the API.

=head2 data

    my $hashref = $volume->data;

Returns all volume data as a hashref (for JSON serialization).

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
