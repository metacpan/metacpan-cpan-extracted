package WWW::Hetzner::Cloud::API::Datacenters;
# ABSTRACT: Hetzner Cloud Datacenters API

our $VERSION = '0.101';

use Moo;
with 'WWW::Hetzner::Role::Pagination';
use Carp qw(croak);
use WWW::Hetzner::Cloud::Datacenter;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::Datacenter->new(
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

    my $result = $self->client->get('/datacenters', params => \%params);
    return ($self->_wrap_list($result->{datacenters} // []), $result->{meta});
}

sub list {
    my ($self, %params) = @_;

    my ($entities) = $self->_list_page(%params);
    return $entities;
}



sub get {
    my ($self, $id) = @_;
    croak "Datacenter ID required" unless $id;

    my $result = $self->client->get("/datacenters/$id");
    return $self->_wrap($result->{datacenter});
}


sub get_by_name {
    my ($self, $name) = @_;
    croak "Name required" unless $name;

    my $datacenters = $self->list_all;
    for my $dc (@$datacenters) {
        return $dc if $dc->name eq $name;
    }
    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::Datacenters - Hetzner Cloud Datacenters API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_API_TOKEN});

    # List all datacenters
    my $datacenters = $cloud->datacenters->list_all;

    # Get by name
    my $dc = $cloud->datacenters->get_by_name('fsn1-dc14');
    printf "Datacenter: %s at %s\n", $dc->name, $dc->location;

=head1 DESCRIPTION

This module provides access to Hetzner Cloud datacenters. Datacenters are
virtual subdivisions of locations with specific server type availability.
All methods return L<WWW::Hetzner::Cloud::Datacenter> objects.

=head2 list

    my $datacenters = $cloud->datacenters->list;

Returns an arrayref of L<WWW::Hetzner::Cloud::Datacenter> objects.

=head2 list_all

    my $entities = $controller->list_all(per_page => 50, %filters);

Returns a combined arrayref. Inherited from
L<WWW::Hetzner::Role::Pagination/list_all>. Unlike L</list>, which fetches
one page, it follows every subsequent page starting at page 1 or the supplied
C<page>. It carries C<per_page>, filters, and sort values to every request.

=head2 get

    my $datacenter = $cloud->datacenters->get($id);

Returns a L<WWW::Hetzner::Cloud::Datacenter> object.

=head2 get_by_name

    my $datacenter = $cloud->datacenters->get_by_name('fsn1-dc14');

Returns a L<WWW::Hetzner::Cloud::Datacenter> object. Returns undef if not found.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client

=item * L<WWW::Hetzner::Cloud::Datacenter> - Datacenter entity class

=item * L<WWW::Hetzner::CLI::Cmd::Datacenter> - Datacenter CLI commands

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
