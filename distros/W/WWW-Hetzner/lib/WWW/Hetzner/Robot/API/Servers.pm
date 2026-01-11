package WWW::Hetzner::Robot::API::Servers;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Robot Servers API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Robot::Server;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Robot::Server->new(
        client => $self->client,
        %$data,
    );
}

sub _wrap_list {
    my ($self, $list) = @_;
    return [ map { $self->_wrap($_->{server}) } @$list ];
}

sub list {
    my ($self) = @_;
    my $result = $self->client->get('/server');
    return $self->_wrap_list($result // []);
}


sub get {
    my ($self, $server_number) = @_;
    croak "Server number required" unless $server_number;
    my $result = $self->client->get("/server/$server_number");
    return $self->_wrap($result->{server});
}


sub update {
    my ($self, $server_number, %params) = @_;
    croak "Server number required" unless $server_number;
    my $result = $self->client->post("/server/$server_number", \%params);
    return $self->_wrap($result->{server});
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::API::Servers - Hetzner Robot Servers API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $robot = WWW::Hetzner::Robot->new(...);

    # List all servers
    my $servers = $robot->servers->list;

    for my $server (@$servers) {
        printf "%s: %s (%s)\n",
            $server->server_number,
            $server->server_name,
            $server->server_ip;
    }

    # Get specific server
    my $server = $robot->servers->get(123456);

    # Update server name
    $robot->servers->update(123456, server_name => 'new-name');

=head2 list

    my $servers = $robot->servers->list;

Returns arrayref of L<WWW::Hetzner::Robot::Server> objects.

=head2 get

    my $server = $robot->servers->get($server_number);

Returns L<WWW::Hetzner::Robot::Server> object.

=head2 update

    my $server = $robot->servers->update($server_number, server_name => 'new-name');

Updates server and returns L<WWW::Hetzner::Robot::Server> object.

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
