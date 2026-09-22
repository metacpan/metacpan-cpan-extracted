package WWW::Hetzner::Cloud::API::Zones;
# ABSTRACT: Hetzner Cloud DNS Zones API

our $VERSION = '0.101';

use Moo;
with 'WWW::Hetzner::Role::Pagination';
use Carp qw(croak);
use WWW::Hetzner::Cloud::API::RRSets;
use WWW::Hetzner::Cloud::Zone;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

with 'WWW::Hetzner::Role::HasActions';

sub _wrap {
    my ($self, $data, %extra) = @_;
    return WWW::Hetzner::Cloud::Zone->new(
        client => $self->client,
        %$data,
        %extra,
    );
}

sub _wrap_list {
    my ($self, $list) = @_;
    return [ map { $self->_wrap($_) } @$list ];
}


sub _list_page {
    my ($self, %params) = @_;

    my $result = $self->client->get('/zones', params => \%params);
    return ($self->_wrap_list($result->{zones} // []), $result->{meta});
}

sub list {
    my ($self, %params) = @_;

    my ($entities) = $self->_list_page(%params);
    return $entities;
}



sub list_by_label {
    my ($self, $label_selector) = @_;
    return $self->list(label_selector => $label_selector);
}


sub get {
    my ($self, $id) = @_;
    croak "Zone ID required" unless $id;

    my $result = $self->client->get("/zones/$id");
    return $self->_wrap($result->{zone});
}


sub create {
    my ($self, %params) = @_;

    croak "name required" unless $params{name};

    my $body = {
        name => $params{name},
    };

    $body->{labels} = $params{labels} if $params{labels};
    $body->{ttl}    = $params{ttl}    if $params{ttl};

    my $result = $self->client->post('/zones', $body);
    return $self->_wrap(
        $result->{zone},
        action => $self->_wrap_action($result->{action}),
    );
}


sub update {
    my ($self, $id, %params) = @_;
    croak "Zone ID required" unless $id;

    my $body = {};
    $body->{name}   = $params{name}   if exists $params{name};
    $body->{labels} = $params{labels} if exists $params{labels};

    my $result = $self->client->put("/zones/$id", $body);
    return $self->_wrap($result->{zone});
}


sub delete {
    my ($self, $id) = @_;
    croak "Zone ID required" unless $id;

    my $result = $self->client->delete("/zones/$id");
    return $self->_wrap_action($result->{action});
}


sub export {
    my ($self, $id) = @_;
    croak "Zone ID required" unless $id;

    my $result = $self->client->get("/zones/$id/export");
    return $result;
}


sub rrsets {
    my ($self, $zone_id) = @_;
    croak "Zone ID required" unless $zone_id;

    return WWW::Hetzner::Cloud::API::RRSets->new(
        client  => $self->client,
        zone_id => $zone_id,
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::Zones - Hetzner Cloud DNS Zones API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_API_TOKEN});

    # List all zones
    my $zones = $cloud->zones->list_all;

    # Create a zone
    my $zone = $cloud->zones->create(
        name   => 'example.com',
        ttl    => 3600,
        labels => { env => 'prod' },
    );

    # Zone is a WWW::Hetzner::Cloud::Zone object
    print $zone->id, "\n";
    print $zone->name, "\n";

    # Access RRSets directly from zone object
    my $records = $zone->rrsets->list;
    $zone->rrsets->add_a('www', '1.2.3.4');

    # Update zone
    $zone->name('newdomain.com');
    $zone->update;

    # Delete zone
    $zone->delete;

=head1 DESCRIPTION

This module provides the API for managing Hetzner Cloud DNS zones.
All methods return L<WWW::Hetzner::Cloud::Zone> objects.

=head2 list

    my $zones = $cloud->zones->list;
    my $zones = $cloud->zones->list(name => 'example.com');
    my $zones = $cloud->zones->list(label_selector => 'env=prod');

Returns an arrayref of L<WWW::Hetzner::Cloud::Zone> objects.
Optional parameters: name, label_selector, sort, page, per_page.

=head2 list_all

    my $entities = $controller->list_all(per_page => 50, %filters);

Returns a combined arrayref. Inherited from
L<WWW::Hetzner::Role::Pagination/list_all>. Unlike L</list>, which fetches
one page, it follows every subsequent page starting at page 1 or the supplied
C<page>. It carries C<per_page>, filters, and sort values to every request.

=head2 list_by_label

    my $zones = $cloud->zones->list_by_label('env=production');

Convenience method to list zones by label selector.

=head2 get

    my $zone = $cloud->zones->get($id);

Returns a L<WWW::Hetzner::Cloud::Zone> object.

=head2 create

    my $zone = $cloud->zones->create(
        name   => 'example.com',  # required
        ttl    => 3600,           # optional (default TTL)
        labels => { env => 'prod' },  # optional
    );

Creates a new DNS zone. Returns a L<WWW::Hetzner::Cloud::Zone> object.

=head2 update

    $cloud->zones->update($id, name => 'newdomain.com', labels => { env => 'dev' });

Updates zone name or labels. Returns a L<WWW::Hetzner::Cloud::Zone> object.

=head2 delete

    my $action = $cloud->zones->delete($id);

Deletes a zone and all its RRSets. Returns the L<WWW::Hetzner::Action>
tracking the deletion; call C<< $action->wait >> to block until the zone is
gone.

=head2 export

    my $zonefile = $cloud->zones->export($id);

Exports the zone as a standard zone file format.

=head2 rrsets

    my $rrsets = $cloud->zones->rrsets($zone_id);
    my $records = $rrsets->list;

Returns a L<WWW::Hetzner::Cloud::API::RRSets> object for managing records in this zone.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client

=item * L<WWW::Hetzner::Cloud::Zone> - Zone entity class

=item * L<WWW::Hetzner::Cloud::API::RRSets> - RRSets (DNS records) API

=item * L<WWW::Hetzner::CLI::Cmd::Zone> - Zone CLI commands

=item * L<WWW::Hetzner> - Main umbrella module

=back

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
