package WWW::Hetzner::Cloud::API::ISOs;
# ABSTRACT: Hetzner Cloud ISOs API

our $VERSION = '0.101';

use Moo;
with 'WWW::Hetzner::Role::Pagination';
use Carp qw(croak);
use WWW::Hetzner::Cloud::ISO;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::ISO->new(
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

    my $result = $self->client->get('/isos', params => \%params);
    return ($self->_wrap_list($result->{isos} // []), $result->{meta});
}

sub list {
    my ($self, %params) = @_;

    my ($entities) = $self->_list_page(%params);
    return $entities;
}



sub get {
    my ($self, $id) = @_;
    croak "ISO ID required" unless $id;

    my $result = $self->client->get("/isos/$id");
    return $self->_wrap($result->{iso});
}


sub get_by_name {
    my ($self, $name) = @_;
    croak "Name required" unless $name;

    my $isos = $self->list_all(name => $name);
    for my $iso (@$isos) {
        return $iso if $iso->name eq $name;
    }
    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::ISOs - Hetzner Cloud ISOs API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_API_TOKEN});

    # List ISOs
    my $isos = $cloud->isos->list;

    # List only ARM ISOs
    my $arm = $cloud->isos->list(architecture => 'arm');

    # Get by ID
    my $iso = $cloud->isos->get(4711);

    # Get by name (the name is what attach_iso takes)
    my $netboot = $cloud->isos->get_by_name('netboot.xyz-arm64.iso');

=head1 DESCRIPTION

This module provides access to Hetzner Cloud ISO images. ISOs can be attached
to a server with C<< $cloud->servers->attach_iso($server_id, $name) >>.
All methods return L<WWW::Hetzner::Cloud::ISO> objects.

ISOs are read-only resources.

=head2 list

    my $isos = $cloud->isos->list;
    my $isos = $cloud->isos->list(architecture => 'x86');
    my $isos = $cloud->isos->list(name => 'netboot.xyz.iso');

Returns an arrayref of L<WWW::Hetzner::Cloud::ISO> objects.

Supported parameters are C<name>, C<architecture>,
C<include_architecture_wildcard>, C<page> and C<per_page>. Without
C<per_page> the API returns its default page size, which is smaller than the
number of available public ISOs -- filter, or page through the result.

=head2 list_all

    my $entities = $controller->list_all(per_page => 50, %filters);

Returns a combined arrayref. Inherited from
L<WWW::Hetzner::Role::Pagination/list_all>. Unlike L</list>, which fetches
one page, it follows every subsequent page starting at page 1 or the supplied
C<page>. It carries C<per_page>, filters, and sort values to every request.

=head2 get

    my $iso = $cloud->isos->get($id);

Returns a L<WWW::Hetzner::Cloud::ISO> object.

=head2 get_by_name

    my $iso = $cloud->isos->get_by_name('netboot.xyz.iso');

Returns a L<WWW::Hetzner::Cloud::ISO> object. Returns undef if not found.

Unlike the other read-only resources this filters server-side (the ISO list
is paginated and long), so the lookup is exact rather than a scan.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client

=item * L<WWW::Hetzner::Cloud::ISO> - ISO entity class

=item * L<WWW::Hetzner::CLI::Cmd::Iso> - ISO CLI commands

=item * L<WWW::Hetzner::Cloud::API::Servers> - Servers API (attach_iso, detach_iso)

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
