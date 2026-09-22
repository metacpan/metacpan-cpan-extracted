package WWW::Hetzner::Robot::API::Failover;
# ABSTRACT: Hetzner Robot Failover IP API

our $VERSION = '0.101';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Robot::Failover;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Robot::Failover->new(
        client => $self->client,
        %$data,
    );
}

sub _wrap_list {
    my ($self, $list) = @_;
    return [ map { $self->_wrap($_->{failover}) } @$list ];
}

sub list {
    my ($self) = @_;
    my $result = $self->client->get('/failover');
    return $self->_wrap_list($result // []);
}


sub get {
    my ($self, $ip) = @_;
    croak "Failover IP required" unless $ip;
    my $result = $self->client->get("/failover/$ip");
    return $self->_wrap($result->{failover});
}


sub switch {
    my ($self, $ip, $active_server_ip) = @_;
    croak "Failover IP required" unless $ip;
    croak "Target server IP required" unless $active_server_ip;
    my $result = $self->client->post("/failover/$ip", {
        active_server_ip => $active_server_ip,
    });
    return $self->_wrap($result->{failover});
}


sub delete {
    my ($self, $ip) = @_;
    croak "Failover IP required" unless $ip;
    my $result = $self->client->delete("/failover/$ip");
    return $self->_wrap($result->{failover});
}



1.

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::API::Failover - Hetzner Robot Failover IP API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $robot = WWW::Hetzner::Robot->new(...);

    # List all failover IPs
    my $failovers = $robot->failover->list;

    # Get one failover IP
    my $failover = $robot->failover->get('203.0.113.60');
    print $failover->active_server_ip, "\n";

    # Route it to another server
    $robot->failover->switch('203.0.113.60', '198.51.100.10');

    # Drop the routing
    $robot->failover->delete('203.0.113.60');

=head1 DESCRIPTION

Failover IPs are routed to one of your dedicated servers and can be switched
to another one, which is how a service survives the loss of a machine.

Hetzner rate limits switching hard (50 requests per hour) - a failover switch
is not a health check.

=head2 list

Returns arrayref of L<WWW::Hetzner::Robot::Failover> objects.

=head2 get

    my $failover = $robot->failover->get($failover_ip);

Returns L<WWW::Hetzner::Robot::Failover> object.

=head2 switch

    my $failover = $robot->failover->switch($failover_ip, $target_server_ip);

Routes the failover IP to another server. C<$target_server_ip> is the main IP
of the destination server, or its subnet address for IPv6.

=head2 delete

    $robot->failover->delete($failover_ip);

Deletes the routing of the failover IP. The IP itself stays in the account -
this is not a cancellation.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Robot> - Main Robot API client

=item * L<WWW::Hetzner::Robot::Failover> - Failover IP entity class

=item * L<WWW::Hetzner::Robot::CLI::Cmd::Failover> - Failover CLI commands

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
