package WWW::Hetzner::Cloud::API::PlacementGroups;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Placement Groups API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Cloud::PlacementGroup;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::PlacementGroup->new(
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

    my $result = $self->client->get('/placement_groups', params => \%params);
    return $self->_wrap_list($result->{placement_groups} // []);
}


sub get {
    my ($self, $id) = @_;
    croak "Placement Group ID required" unless $id;

    my $result = $self->client->get("/placement_groups/$id");
    return $self->_wrap($result->{placement_group});
}


sub create {
    my ($self, %params) = @_;

    croak "name required" unless $params{name};
    croak "type required" unless $params{type};

    my $body = {
        name => $params{name},
        type => $params{type},
    };

    $body->{labels} = $params{labels} if $params{labels};

    my $result = $self->client->post('/placement_groups', $body);
    return $self->_wrap($result->{placement_group});
}


sub update {
    my ($self, $id, %params) = @_;
    croak "Placement Group ID required" unless $id;

    my $body = {};
    $body->{name}   = $params{name}   if exists $params{name};
    $body->{labels} = $params{labels} if exists $params{labels};

    my $result = $self->client->put("/placement_groups/$id", $body);
    return $self->_wrap($result->{placement_group});
}


sub delete {
    my ($self, $id) = @_;
    croak "Placement Group ID required" unless $id;

    return $self->client->delete("/placement_groups/$id");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::PlacementGroups - Hetzner Cloud Placement Groups API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $cloud = WWW::Hetzner::Cloud->new(token => $token);

    # List placement groups
    my $pgs = $cloud->placement_groups->list;

    # Create placement group
    my $pg = $cloud->placement_groups->create(
        name => 'my-group',
        type => 'spread',
    );

    # Use with server creation
    $cloud->servers->create(
        name            => 'my-server',
        server_type     => 'cx23',
        image           => 'debian-12',
        placement_group => $pg->id,
    );

    # Delete
    $cloud->placement_groups->delete($pg->id);

=head1 DESCRIPTION

This module provides the API for managing Hetzner Cloud placement groups.
Placement groups allow you to control the physical placement of servers
to increase availability. All methods return L<WWW::Hetzner::Cloud::PlacementGroup> objects.

=head2 list

    my $pgs = $cloud->placement_groups->list;
    my $pgs = $cloud->placement_groups->list(label_selector => 'env=prod');

Returns arrayref of L<WWW::Hetzner::Cloud::PlacementGroup> objects.

=head2 get

    my $pg = $cloud->placement_groups->get($id);

Returns L<WWW::Hetzner::Cloud::PlacementGroup> object.

=head2 create

    my $pg = $cloud->placement_groups->create(
        name   => 'my-group',    # required
        type   => 'spread',      # required
        labels => { ... },       # optional
    );

Creates placement group. Returns L<WWW::Hetzner::Cloud::PlacementGroup> object.

=head2 update

    $cloud->placement_groups->update($id, name => 'new-name', labels => { ... });

Updates placement group. Returns L<WWW::Hetzner::Cloud::PlacementGroup> object.

=head2 delete

    $cloud->placement_groups->delete($id);

Deletes placement group.

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
