package WWW::Hetzner::Cloud::API::Actions;
# ABSTRACT: Hetzner Cloud Actions API

our $VERSION = '0.101';

use Moo;
with 'WWW::Hetzner::Role::Pagination';
use Carp qw(croak);
use WWW::Hetzner::Action;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Action->new(
        client => $self->client,
        %$data,
    );
}

sub _wrap_list {
    my ($self, $list) = @_;
    return [ map { $self->_wrap($_) } @$list ];
}


sub get {
    my ($self, $id) = @_;
    croak "Action ID required" unless $id;

    my $result = $self->client->get("/actions/$id");
    return $self->_wrap($result->{action});
}


sub _list_page {
    my ($self, %params) = @_;

    my $result = $self->client->get('/actions', params => \%params);
    return ($self->_wrap_list($result->{actions} // []), $result->{meta});
}

sub list {
    my ($self, %params) = @_;

    my ($entities) = $self->_list_page(%params);
    return $entities;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::Actions - Hetzner Cloud Actions API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_API_TOKEN});

    # List all actions
    my $actions = $cloud->actions->list_all;

    # Fetch a single action
    my $action = $cloud->actions->get($id);

    # Action is a WWW::Hetzner::Action object
    print $action->status, "\n";

    # Block until it finishes
    $action->wait;

=head1 DESCRIPTION

This module provides the API for reading Hetzner Cloud actions, the async
job objects returned by resource-mutating calls. All methods return
L<WWW::Hetzner::Action> objects.

=head2 get

    my $action = $cloud->actions->get($id);

Returns a L<WWW::Hetzner::Action> object.

=head2 list

    my $actions = $cloud->actions->list;
    my $actions = $cloud->actions->list(status => 'running');

Returns an arrayref of L<WWW::Hetzner::Action> objects.
Optional parameters: status, sort.

=head2 list_all

    my $entities = $controller->list_all(per_page => 50, %filters);

Returns a combined arrayref. Inherited from
L<WWW::Hetzner::Role::Pagination/list_all>. Unlike L</list>, which fetches
one page, it follows every subsequent page starting at page 1 or the supplied
C<page>. It carries C<per_page>, filters, and sort values to every request.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client

=item * L<WWW::Hetzner::Action> - Action entity class

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
