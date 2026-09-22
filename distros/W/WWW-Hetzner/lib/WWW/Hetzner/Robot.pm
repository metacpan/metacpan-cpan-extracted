package WWW::Hetzner::Robot;

# ABSTRACT: Perl client for Hetzner Robot API (Dedicated Servers)

use Moo;
use URI::Escape ();
use WWW::Hetzner::Robot::API::Servers;
use WWW::Hetzner::Robot::API::Keys;
use WWW::Hetzner::Robot::API::IPs;
use WWW::Hetzner::Robot::API::Reset;
use WWW::Hetzner::Robot::API::Traffic;
use WWW::Hetzner::Robot::API::Boot;
use WWW::Hetzner::Robot::API::RDNS;
use WWW::Hetzner::Robot::API::Failover;
use namespace::clean;

our $VERSION = '0.101';


has user => (
    is      => 'ro',
    default => sub { $ENV{HETZNER_ROBOT_USER} },
);


has password => (
    is      => 'ro',
    default => sub { $ENV{HETZNER_ROBOT_PASSWORD} },
);


# For Role::HTTP compatibility
sub token {
    my $self = shift;
    return $self->user && $self->password;
}

sub _check_auth {
    my ($self) = @_;
    unless ($self->user && $self->password) {
        die "No Robot credentials configured.\n\n" .
            "Set credentials via:\n" .
            "  Environment: HETZNER_ROBOT_USER and HETZNER_ROBOT_PASSWORD\n" .
            "  Options:     --user and --password\n\n" .
            "Get credentials at: https://robot.hetzner.com/preferences/index\n";
    }
}

has base_url => (
    is      => 'ro',
    default => 'https://robot-ws.your-server.de',
);


with 'WWW::Hetzner::Role::HTTP';

around _request => sub {
    my ($orig, $self, @args) = @_;
    $self->_check_auth;
    return $self->$orig(@args);
};

# Override auth for Basic Auth
sub _set_auth {
    my ($self, $headers) = @_;
    require MIME::Base64;
    $headers->{Authorization} = 'Basic ' .
        MIME::Base64::encode_base64($self->user . ':' . $self->password, '');
}


sub _content_type { 'application/x-www-form-urlencoded' }

sub _encode_body {
    my ($self, $body) = @_;
    my @pairs;

    for my $key (keys %$body) {
        my $value = $body->{$key};
        my $is_array = ref $value eq 'ARRAY';
        my $form_key = $is_array && $key !~ /\[\]\z/ ? "$key\[\]" : $key;
        my @values = $is_array ? @$value : ($value);

        for my $value (@values) {
            next unless defined $value;
            push @pairs, URI::Escape::uri_escape_utf8($form_key) . '=' .
                URI::Escape::uri_escape_utf8($value);
        }
    }

    return join '&', @pairs;
}


# Resource accessors
has servers => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Robot::API::Servers->new(client => shift) },
);


has keys => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Robot::API::Keys->new(client => shift) },
);


has ips => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Robot::API::IPs->new(client => shift) },
);


has reset => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Robot::API::Reset->new(client => shift) },
);


has traffic => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Robot::API::Traffic->new(client => shift) },
);


has boot => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Robot::API::Boot->new(client => shift) },
);


has rdns => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Robot::API::RDNS->new(client => shift) },
);


has failover => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Robot::API::Failover->new(client => shift) },
);



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot - Perl client for Hetzner Robot API (Dedicated Servers)

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::Robot;

    my $robot = WWW::Hetzner::Robot->new(
        user     => $ENV{HETZNER_ROBOT_USER},
        password => $ENV{HETZNER_ROBOT_PASSWORD},
    );

    # List servers
    my $servers = $robot->servers->list;

    # Get server details
    my $server = $robot->servers->get(123456);
    print $server->name, "\n";
    print $server->product, "\n";

    # Boot the rescue system (arm, then reset into it)
    my $rescue = $robot->boot->enable_rescue(123456, os => 'linux');
    print $rescue->{password}, "\n";
    $robot->reset->execute(123456, 'hw');

    # Reset server
    $robot->reset->execute(123456, 'sw');  # software reset
    $robot->reset->execute(123456, 'hw');  # hardware reset

    # Manage SSH keys
    my $keys = $robot->keys->list;
    $robot->keys->create(
        name => 'my-key',
        data => 'ssh-ed25519 AAAA...',
    );

=head1 DESCRIPTION

This module provides access to the Hetzner Robot API for managing dedicated
servers, IPs, SSH keys, and server resets.

Uses HTTP Basic Auth (user/password) instead of Bearer tokens.

=head1 RESOURCES

=over 4

=item * servers - Dedicated server management

=item * keys - SSH key management

=item * ips - IP address management

=item * reset - Server reset (software/hardware)

=item * traffic - Traffic statistics

=item * boot - Boot configuration (rescue system, Linux/VNC/Windows installation)

=item * rdns - Reverse DNS entries

=item * failover - Failover IP routing

=back

=head2 user

Robot webservice username. Defaults to C<HETZNER_ROBOT_USER> environment variable.

=head2 password

Robot webservice password. Defaults to C<HETZNER_ROBOT_PASSWORD> environment variable.

=head2 base_url

Base URL for the Robot API. Defaults to C<https://robot-ws.your-server.de>.

=head2 _set_auth

Override for Basic Auth instead of Bearer token authentication.

=head2 _encode_body

Encode Robot request bodies as C<application/x-www-form-urlencoded>. Arrayref
values become repeated C<name[]> fields without duplicating an existing C<[]> suffix.

=head2 servers

Returns a L<WWW::Hetzner::Robot::API::Servers> instance for managing dedicated servers.

=head2 keys

Returns a L<WWW::Hetzner::Robot::API::Keys> instance for managing SSH keys.

=head2 ips

Returns a L<WWW::Hetzner::Robot::API::IPs> instance for managing IP addresses.

=head2 reset

Returns a L<WWW::Hetzner::Robot::API::Reset> instance for server reset operations.

=head2 traffic

Returns a L<WWW::Hetzner::Robot::API::Traffic> instance for traffic statistics.

=head2 boot

Returns a L<WWW::Hetzner::Robot::API::Boot> instance for boot configuration
(rescue system, Linux, VNC and Windows installation).

=head2 rdns

Returns a L<WWW::Hetzner::Robot::API::RDNS> instance for reverse DNS entries.

=head2 failover

Returns a L<WWW::Hetzner::Robot::API::Failover> instance for failover IP routing.

=head1 ENVIRONMENT

=over 4

=item * C<HETZNER_ROBOT_USER> - Robot webservice username

=item * C<HETZNER_ROBOT_PASSWORD> - Robot webservice password

=back

=head1 SEE ALSO

L<WWW::Hetzner>, L<https://robot.hetzner.com/doc/webservice/en.html>

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
