package WWW::Hetzner::Cloud::Firewall;
# ABSTRACT: Hetzner Cloud Firewall object

our $VERSION = '0.101';

use Moo;
use Carp qw(croak);
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has id => ( is => 'ro' );


has name => ( is => 'rw' );


has rules => ( is => 'rw', default => sub { [] } );


has applied_to => ( is => 'ro', default => sub { [] } );


has labels => ( is => 'rw', default => sub { {} } );


has created => ( is => 'ro' );


has actions => ( is => 'ro', default => sub { [] } );


# Actions
sub update {
    my ($self) = @_;
    croak "Cannot update firewall without ID" unless $self->id;

    my $result = $self->_client->put("/firewalls/" . $self->id, {
        name   => $self->name,
        labels => $self->labels,
    });
    return $self;
}


sub delete {
    my ($self) = @_;
    croak "Cannot delete firewall without ID" unless $self->id;

    $self->_client->delete("/firewalls/" . $self->id);
    return 1;
}


sub set_rules {
    my ($self, @rules) = @_;
    croak "Cannot modify firewall without ID" unless $self->id;

    my $actions = $self->_client->firewalls->set_rules($self->id, \@rules);
    $self->rules(\@rules);
    return $actions;
}


sub apply_to_resources {
    my ($self, @resources) = @_;
    croak "Cannot modify firewall without ID" unless $self->id;

    return $self->_client->firewalls->apply_to_resources($self->id, @resources);
}


sub remove_from_resources {
    my ($self, @resources) = @_;
    croak "Cannot modify firewall without ID" unless $self->id;

    return $self->_client->firewalls->remove_from_resources($self->id, @resources);
}


sub refresh {
    my ($self) = @_;
    croak "Cannot refresh firewall without ID" unless $self->id;

    my $result = $self->_client->get("/firewalls/" . $self->id);
    my $data = $result->{firewall};

    $self->name($data->{name});
    $self->rules($data->{rules} // []);
    $self->labels($data->{labels} // {});

    return $self;
}


sub data {
    my ($self) = @_;
    return {
        id         => $self->id,
        name       => $self->name,
        rules      => $self->rules,
        applied_to => $self->applied_to,
        labels     => $self->labels,
        created    => $self->created,
    };
}



1.

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::Firewall - Hetzner Cloud Firewall object

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $fw = $cloud->firewalls->get($id);

    # Read attributes
    print $fw->name, "\n";

    # Set rules
    $fw->set_rules(
        { direction => 'in', protocol => 'tcp', port => '22', source_ips => ['0.0.0.0/0'] },
        { direction => 'in', protocol => 'tcp', port => '443', source_ips => ['0.0.0.0/0'] },
    );

    # Apply to server
    $fw->apply_to_resources({ type => 'server', server => { id => 123 } });

    # Update name
    $fw->name('new-name');
    $fw->update;

    # Delete
    $fw->delete;

=head1 DESCRIPTION

This class represents a Hetzner Cloud firewall. Objects are returned by
L<WWW::Hetzner::Cloud::API::Firewalls> methods.

=head2 id

Firewall ID (read-only).

=head2 name

Firewall name (read-write).

=head2 rules

Arrayref of firewall rules (read-write via set_rules method).

=head2 applied_to

Arrayref of resources this firewall is applied to (read-only).

=head2 labels

Labels hash (read-write).

=head2 created

Creation timestamp (read-only).

=head2 actions

Arrayref of L<WWW::Hetzner::Action> objects returned by C<create>.
Empty arrayref when the API did not emit any (read-only). Not maintained
afterwards.

=head2 update

    $fw->name('new-name');
    $fw->update;

Saves changes to name and labels.

=head2 delete

    $fw->delete;

Deletes the firewall.

=head2 set_rules

    $fw->set_rules(
        { direction => 'in', protocol => 'tcp', port => '22', source_ips => ['0.0.0.0/0'] },
        { direction => 'in', protocol => 'tcp', port => '443', source_ips => ['0.0.0.0/0'] },
    );

Set firewall rules.

=head2 apply_to_resources

    $fw->apply_to_resources({ type => 'server', server => { id => 123 } });

Apply firewall to resources.

=head2 remove_from_resources

    $fw->remove_from_resources({ type => 'server', server => { id => 123 } });

Remove firewall from resources.

=head2 refresh

    $fw->refresh;

Reloads firewall data from the API.

=head2 data

    my $hashref = $fw->data;

Returns all firewall data as a hashref (for JSON serialization).

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud::API::Firewalls> - Firewalls API

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client

=item * L<WWW::Hetzner::Cloud::Server> - Server entity

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
