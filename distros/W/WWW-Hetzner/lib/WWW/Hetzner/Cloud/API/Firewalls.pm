package WWW::Hetzner::Cloud::API::Firewalls;
# ABSTRACT: Hetzner Cloud Firewalls API

our $VERSION = '0.101';

use Moo;
with 'WWW::Hetzner::Role::Pagination';
use Carp qw(croak);
use WWW::Hetzner::Cloud::Firewall;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

with 'WWW::Hetzner::Role::HasActions';

sub _wrap {
    my ($self, $data, %extra) = @_;
    return WWW::Hetzner::Cloud::Firewall->new(
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

    my $result = $self->client->get('/firewalls', params => \%params);
    return ($self->_wrap_list($result->{firewalls} // []), $result->{meta});
}

sub list {
    my ($self, %params) = @_;

    my ($entities) = $self->_list_page(%params);
    return $entities;
}



sub get {
    my ($self, $id) = @_;
    croak "Firewall ID required" unless $id;

    my $result = $self->client->get("/firewalls/$id");
    return $self->_wrap($result->{firewall});
}


sub create {
    my ($self, %params) = @_;

    croak "name required" unless $params{name};

    my $body = {
        name => $params{name},
    };

    $body->{rules}    = $params{rules}    if $params{rules};
    $body->{labels}   = $params{labels}   if $params{labels};
    $body->{apply_to} = $params{apply_to} if $params{apply_to};

    my $result = $self->client->post('/firewalls', $body);
    return $self->_wrap(
        $result->{firewall},
        actions => $self->_wrap_actions($result->{actions}),
    );
}


sub update {
    my ($self, $id, %params) = @_;
    croak "Firewall ID required" unless $id;

    my $body = {};
    $body->{name}   = $params{name}   if exists $params{name};
    $body->{labels} = $params{labels} if exists $params{labels};

    my $result = $self->client->put("/firewalls/$id", $body);
    return $self->_wrap($result->{firewall});
}


sub delete {
    my ($self, $id) = @_;
    croak "Firewall ID required" unless $id;

    return $self->client->delete("/firewalls/$id");
}


sub set_rules {
    my ($self, $id, $rules) = @_;
    croak "Firewall ID required" unless $id;
    croak "Rules arrayref required" unless ref $rules eq 'ARRAY';

    return $self->_wrap_actions(
        $self->client->post("/firewalls/$id/actions/set_rules", {
            rules => $rules,
        })->{actions}
    );
}


sub apply_to_resources {
    my ($self, $id, @resources) = @_;
    croak "Firewall ID required" unless $id;

    return $self->_wrap_actions(
        $self->client->post("/firewalls/$id/actions/apply_to_resources", {
            apply_to => \@resources,
        })->{actions}
    );
}


sub remove_from_resources {
    my ($self, $id, @resources) = @_;
    croak "Firewall ID required" unless $id;

    return $self->_wrap_actions(
        $self->client->post("/firewalls/$id/actions/remove_from_resources", {
            remove_from => \@resources,
        })->{actions}
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::Firewalls - Hetzner Cloud Firewalls API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $cloud = WWW::Hetzner::Cloud->new(token => $token);

    # List firewalls
    my $firewalls = $cloud->firewalls->list;

    # Create firewall with rules
    my $fw = $cloud->firewalls->create(
        name  => 'web-firewall',
        rules => [
            {
                direction   => 'in',
                protocol    => 'tcp',
                port        => '22',
                source_ips  => ['0.0.0.0/0', '::/0'],
            },
            {
                direction   => 'in',
                protocol    => 'tcp',
                port        => '80',
                source_ips  => ['0.0.0.0/0', '::/0'],
            },
        ],
    );

    # Apply to server
    $cloud->firewalls->apply_to_resources($fw->id,
        { type => 'server', server => { id => 123 } },
    );

    # Delete
    $cloud->firewalls->delete($fw->id);

=head1 DESCRIPTION

This module provides the API for managing Hetzner Cloud firewalls.
All methods return L<WWW::Hetzner::Cloud::Firewall> objects.

=head2 list

    my $firewalls = $cloud->firewalls->list;
    my $firewalls = $cloud->firewalls->list(label_selector => 'env=prod');

Returns arrayref of L<WWW::Hetzner::Cloud::Firewall> objects.

=head2 list_all

    my $entities = $controller->list_all(per_page => 50, %filters);

Returns a combined arrayref. Inherited from
L<WWW::Hetzner::Role::Pagination/list_all>. Unlike L</list>, which fetches
one page, it follows every subsequent page starting at page 1 or the supplied
C<page>. It carries C<per_page>, filters, and sort values to every request.

=head2 get

    my $firewall = $cloud->firewalls->get($id);

Returns L<WWW::Hetzner::Cloud::Firewall> object.

=head2 create

    my $fw = $cloud->firewalls->create(
        name     => 'my-firewall',  # required
        rules    => [ ... ],        # optional
        labels   => { ... },        # optional
        apply_to => [ ... ],        # optional
    );

Creates firewall. Returns L<WWW::Hetzner::Cloud::Firewall> object.

=head2 update

    $cloud->firewalls->update($id, name => 'new-name', labels => { ... });

Updates firewall. Returns L<WWW::Hetzner::Cloud::Firewall> object.

=head2 delete

    $cloud->firewalls->delete($id);

Deletes firewall.

=head2 set_rules

    $cloud->firewalls->set_rules($id, \@rules);

Set firewall rules, replacing all existing rules.

=head2 apply_to_resources

    $cloud->firewalls->apply_to_resources($id,
        { type => 'server', server => { id => 123 } },
    );

Apply firewall to resources.

=head2 remove_from_resources

    $cloud->firewalls->remove_from_resources($id,
        { type => 'server', server => { id => 123 } },
    );

Remove firewall from resources.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client

=item * L<WWW::Hetzner::Cloud::Firewall> - Firewall entity class

=item * L<WWW::Hetzner::CLI::Cmd::Firewall> - Firewall CLI commands

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
