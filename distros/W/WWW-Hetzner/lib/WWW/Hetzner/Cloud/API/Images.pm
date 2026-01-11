package WWW::Hetzner::Cloud::API::Images;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Images API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Cloud::Image;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::Image->new(
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

    my $result = $self->client->get('/images', params => \%params);
    return $self->_wrap_list($result->{images} // []);
}


sub get {
    my ($self, $id) = @_;
    croak "Image ID required" unless $id;

    my $result = $self->client->get("/images/$id");
    return $self->_wrap($result->{image});
}


sub get_by_name {
    my ($self, $name) = @_;
    croak "Name required" unless $name;

    my $images = $self->list;
    for my $image (@$images) {
        return $image if $image->name eq $name;
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::Images - Hetzner Cloud Images API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_API_TOKEN});

    # List all images
    my $images = $cloud->images->list;

    # Filter by type
    my $snapshots = $cloud->images->list(type => 'snapshot');

    # Get by name
    my $debian = $cloud->images->get_by_name('debian-13');
    printf "Image: %s (%s)\n", $debian->name, $debian->description;

=head1 DESCRIPTION

This module provides access to Hetzner Cloud images. Images can be system
images (provided by Hetzner), snapshots (user-created), or backups.
All methods return L<WWW::Hetzner::Cloud::Image> objects.

=head2 list

    my $images = $cloud->images->list;
    my $images = $cloud->images->list(type => 'system');

Returns an arrayref of L<WWW::Hetzner::Cloud::Image> objects. Optional parameters:

=over 4

=item * type - Filter by type: system, snapshot, backup

=item * status - Filter by status: available, creating

=item * name - Filter by name

=back

=head2 get

    my $image = $cloud->images->get($id);

Returns a L<WWW::Hetzner::Cloud::Image> object.

=head2 get_by_name

    my $image = $cloud->images->get_by_name('debian-13');

Returns a L<WWW::Hetzner::Cloud::Image> object. Returns undef if not found.

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
