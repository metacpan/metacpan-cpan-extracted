package WWW::Hetzner::Cloud::API::Datacenters;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Datacenters API

our $VERSION = '0.002';

use Moo;
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


sub list {
    my ($self, %params) = @_;

    my $result = $self->client->get('/datacenters', params => \%params);
    return $self->_wrap_list($result->{datacenters} // []);
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

    my $datacenters = $self->list;
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

version 0.002

=head1 SYNOPSIS

    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_API_TOKEN});

    # List all datacenters
    my $datacenters = $cloud->datacenters->list;

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

=head2 get

    my $datacenter = $cloud->datacenters->get($id);

Returns a L<WWW::Hetzner::Cloud::Datacenter> object.

=head2 get_by_name

    my $datacenter = $cloud->datacenters->get_by_name('fsn1-dc14');

Returns a L<WWW::Hetzner::Cloud::Datacenter> object. Returns undef if not found.

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
