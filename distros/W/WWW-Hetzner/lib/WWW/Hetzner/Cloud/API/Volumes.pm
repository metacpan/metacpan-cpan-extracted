package WWW::Hetzner::Cloud::API::Volumes;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Volumes API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Cloud::Volume;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::Volume->new(
        client => $self->client,
        %$data,
    );
}

sub _wrap_list {
    my ($self, $list) = @_;
    return [ map { $self->_wrap($_) } @$list ];
}


sub list {
    my ($self, %params) = @_;

    my $result = $self->client->get('/volumes', params => \%params);
    return $self->_wrap_list($result->{volumes} // []);
}


sub get {
    my ($self, $id) = @_;
    croak "Volume ID required" unless $id;

    my $result = $self->client->get("/volumes/$id");
    return $self->_wrap($result->{volume});
}


sub create {
    my ($self, %params) = @_;

    croak "name required" unless $params{name};
    croak "size required" unless $params{size};
    croak "location required" unless $params{location};

    my $body = {
        name     => $params{name},
        size     => $params{size},
        location => $params{location},
    };

    $body->{format}    = $params{format}    if $params{format};
    $body->{labels}    = $params{labels}    if $params{labels};
    $body->{automount} = $params{automount} if exists $params{automount};
    $body->{server}    = $params{server}    if $params{server};

    my $result = $self->client->post('/volumes', $body);
    return $self->_wrap($result->{volume});
}


sub delete {
    my ($self, $id) = @_;
    croak "Volume ID required" unless $id;

    return $self->client->delete("/volumes/$id");
}


sub attach {
    my ($self, $id, $server_id, %opts) = @_;
    croak "Volume ID required" unless $id;
    croak "Server ID required" unless $server_id;

    my $body = { server => $server_id };
    $body->{automount} = $opts{automount} ? \1 : \0 if exists $opts{automount};

    return $self->client->post("/volumes/$id/actions/attach", $body);
}


sub detach {
    my ($self, $id) = @_;
    croak "Volume ID required" unless $id;

    return $self->client->post("/volumes/$id/actions/detach", {});
}


sub resize {
    my ($self, $id, $size) = @_;
    croak "Volume ID required" unless $id;
    croak "Size required" unless $size;

    return $self->client->post("/volumes/$id/actions/resize", { size => $size });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::Volumes - Hetzner Cloud Volumes API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $cloud = WWW::Hetzner::Cloud->new(token => $token);

    # List volumes
    my $volumes = $cloud->volumes->list;

    # Create volume
    my $volume = $cloud->volumes->create(
        name     => 'my-volume',
        size     => 50,           # GB
        location => 'fsn1',
        format   => 'ext4',       # optional
    );

    # Attach to server
    $cloud->volumes->attach($volume->id, $server_id);

    # Resize
    $cloud->volumes->resize($volume->id, 100);

    # Delete
    $cloud->volumes->delete($volume->id);

=head1 DESCRIPTION

This module provides the API for managing Hetzner Cloud volumes.
All methods return L<WWW::Hetzner::Cloud::Volume> objects.

=head2 list

    my $volumes = $cloud->volumes->list;
    my $volumes = $cloud->volumes->list(label_selector => 'env=prod');

Returns arrayref of L<WWW::Hetzner::Cloud::Volume> objects.

=head2 get

    my $volume = $cloud->volumes->get($id);

Returns L<WWW::Hetzner::Cloud::Volume> object.

=head2 create

    my $volume = $cloud->volumes->create(
        name     => 'my-volume',  # required
        size     => 50,           # required (GB)
        location => 'fsn1',       # required
        format   => 'ext4',       # optional
        labels   => { ... },      # optional
        automount => 1,           # optional
        server   => $server_id,   # optional
    );

Creates volume. Returns L<WWW::Hetzner::Cloud::Volume> object.

=head2 delete

    $cloud->volumes->delete($id);

Deletes volume.

=head2 attach

    $cloud->volumes->attach($volume_id, $server_id, automount => 1);

Attaches volume to server.

=head2 detach

    $cloud->volumes->detach($volume_id);

Detaches volume.

=head2 resize

    $cloud->volumes->resize($volume_id, $size);

Resizes volume to the specified size in GB.

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
