package WWW::Hetzner::Cloud::API::Locations;
# ABSTRACT: Hetzner Cloud Locations API

our $VERSION = '0.101';

use Moo;
with 'WWW::Hetzner::Role::Pagination';
use Carp qw(croak);
use WWW::Hetzner::Cloud::Location;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::Location->new(
        client => $self->client,
        %$data,
    );
}

sub _wrap_list {
    my ($self, $list) = @_;
    return [ map { $self->_wrap($_) } @$list ];
}


sub _list_page {
    my ($self, %params) = @_;

    my $result = $self->client->get('/locations', params => \%params);
    return ($self->_wrap_list($result->{locations} // []), $result->{meta});
}

sub list {
    my ($self, %params) = @_;

    my ($entities) = $self->_list_page(%params);
    return $entities;
}



sub get {
    my ($self, $id) = @_;
    croak "Location ID required" unless $id;

    my $result = $self->client->get("/locations/$id");
    return $self->_wrap($result->{location});
}


sub get_by_name {
    my ($self, $name) = @_;
    croak "Name required" unless $name;

    my $locations = $self->list_all;
    for my $loc (@$locations) {
        return $loc if $loc->name eq $name;
    }
    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::Locations - Hetzner Cloud Locations API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_API_TOKEN});

    # List all locations
    my $locations = $cloud->locations->list_all;

    # Get by name
    my $fsn1 = $cloud->locations->get_by_name('fsn1');
    printf "Falkenstein: %s, %s\n", $fsn1->city, $fsn1->country;

=head1 DESCRIPTION

This module provides access to Hetzner Cloud locations. Locations are physical
data center sites where servers can be deployed.
All methods return L<WWW::Hetzner::Cloud::Location> objects.

Available locations: fsn1 (Falkenstein), nbg1 (Nuremberg), hel1 (Helsinki),
ash (Ashburn), hil (Hillsboro), sin (Singapore).

=head2 list

    my $locations = $cloud->locations->list;

Returns an arrayref of L<WWW::Hetzner::Cloud::Location> objects.

=head2 list_all

    my $entities = $controller->list_all(per_page => 50, %filters);

Returns a combined arrayref. Inherited from
L<WWW::Hetzner::Role::Pagination/list_all>. Unlike L</list>, which fetches
one page, it follows every subsequent page starting at page 1 or the supplied
C<page>. It carries C<per_page>, filters, and sort values to every request.

=head2 get

    my $location = $cloud->locations->get($id);

Returns a L<WWW::Hetzner::Cloud::Location> object.

=head2 get_by_name

    my $location = $cloud->locations->get_by_name('fsn1');

Returns a L<WWW::Hetzner::Cloud::Location> object. Returns undef if not found.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client

=item * L<WWW::Hetzner::Cloud::Location> - Location entity class

=item * L<WWW::Hetzner::CLI::Cmd::Location> - Location CLI commands

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
