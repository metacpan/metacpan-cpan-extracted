package WWW::Hetzner::Robot::API::Boot;
# ABSTRACT: Hetzner Robot Boot Configuration API

our $VERSION = '0.101';

use Moo;
use Carp qw(croak);
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _option {
    my ($self, $server_number, $variant) = @_;
    croak "Server number required" unless $server_number;
    my $result = $self->client->get("/boot/$server_number/$variant");
    return $result->{$variant};
}

sub _enable {
    my ($self, $server_number, $variant, $body) = @_;
    croak "Server number required" unless $server_number;
    my $result = $self->client->post("/boot/$server_number/$variant", $body);
    return $result->{$variant};
}

sub _disable {
    my ($self, $server_number, $variant) = @_;
    croak "Server number required" unless $server_number;
    my $result = $self->client->delete("/boot/$server_number/$variant");
    return $result->{$variant};
}

sub get {
    my ($self, $server_number) = @_;
    croak "Server number required" unless $server_number;
    my $result = $self->client->get("/boot/$server_number");
    return $result->{boot};
}


sub rescue {
    my ($self, $server_number) = @_;
    return $self->_option($server_number, 'rescue');
}


sub enable_rescue {
    my ($self, $server_number, %params) = @_;
    croak "os required" unless $params{os};

    my $body = { os => $params{os} };
    $body->{authorized_key} = $params{authorized_key} if defined $params{authorized_key};
    $body->{keyboard}       = $params{keyboard}       if defined $params{keyboard};

    return $self->_enable($server_number, 'rescue', $body);
}


sub disable_rescue {
    my ($self, $server_number) = @_;
    return $self->_disable($server_number, 'rescue');
}


sub linux {
    my ($self, $server_number) = @_;
    return $self->_option($server_number, 'linux');
}


sub enable_linux {
    my ($self, $server_number, %params) = @_;
    croak "dist required" unless $params{dist};
    croak "lang required" unless $params{lang};

    my $body = {
        dist => $params{dist},
        lang => $params{lang},
    };
    $body->{authorized_key} = $params{authorized_key} if defined $params{authorized_key};

    return $self->_enable($server_number, 'linux', $body);
}


sub disable_linux {
    my ($self, $server_number) = @_;
    return $self->_disable($server_number, 'linux');
}


sub vnc {
    my ($self, $server_number) = @_;
    return $self->_option($server_number, 'vnc');
}


sub enable_vnc {
    my ($self, $server_number, %params) = @_;
    croak "dist required" unless $params{dist};
    croak "lang required" unless $params{lang};

    return $self->_enable($server_number, 'vnc', {
        dist => $params{dist},
        lang => $params{lang},
    });
}


sub disable_vnc {
    my ($self, $server_number) = @_;
    return $self->_disable($server_number, 'vnc');
}


sub windows {
    my ($self, $server_number) = @_;
    return $self->_option($server_number, 'windows');
}


sub enable_windows {
    my ($self, $server_number, %params) = @_;
    croak "os required"   unless $params{os};
    croak "lang required" unless $params{lang};

    return $self->_enable($server_number, 'windows', {
        os   => $params{os},
        lang => $params{lang},
    });
}


sub disable_windows {
    my ($self, $server_number) = @_;
    return $self->_disable($server_number, 'windows');
}



1.

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::API::Boot - Hetzner Robot Boot Configuration API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $robot = WWW::Hetzner::Robot->new(...);

    # Status of all boot options
    my $boot = $robot->boot->get(123456);

    # Rescue system
    my $rescue = $robot->boot->rescue(123456);
    my $active = $robot->boot->enable_rescue(123456, os => 'linux');
    print $active->{password}, "\n";      # generated root password
    $robot->boot->disable_rescue(123456);

    # Linux installation
    $robot->boot->enable_linux(123456, dist => 'Debian 12 minimal', lang => 'en');
    $robot->boot->disable_linux(123456);

    # VNC installation
    $robot->boot->enable_vnc(123456, dist => 'centOS-5.0', lang => 'en_US');
    $robot->boot->disable_vnc(123456);

    # Windows installation (requires the Windows addon)
    $robot->boot->enable_windows(123456, os => 'Windows Server 2022 Standard Edition', lang => 'en');
    $robot->boot->disable_windows(123456);

=head1 DESCRIPTION

Boot configuration of a dedicated server. This is what turns a bare machine
into something reachable: L</enable_rescue> followed by a reset boots the
rescue system, L</enable_linux> arms the unattended Linux installer.

Every activation returns the generated C<password> for the booted system,
which is only present in the response of the activating call - a later
C<get> shows C<password> as C<null> once the system has been picked up.

The four boot variants are:

=over 4

=item * B<rescue> - Hetzner rescue system (C<linux>, C<vkvm>)

=item * B<linux> - unattended Linux installation

=item * B<vnc> - VNC based installation

=item * B<windows> - Windows installation (needs a purchased Windows addon)

=back

Returns raw hashrefs, like L<WWW::Hetzner::Robot::API::Reset> - boot options
are per-server state, not entities with an identity of their own.

=head2 get

    my $boot = $robot->boot->get($server_number);

Status of all boot options at once, keyed by C<rescue>, C<linux>, C<vnc> and
C<windows>.

=head2 rescue

    my $rescue = $robot->boot->rescue($server_number);

Current rescue system configuration. C<os> lists the available systems while
inactive, and holds the booted one while C<active> is true.

=head2 enable_rescue

    my $rescue = $robot->boot->enable_rescue($server_number,
        os             => 'linux',
        authorized_key => [ 'aa:bb:cc:...' ],   # optional
        keyboard       => 'us',                 # optional, default us
    );

Activates the rescue system. The returned hashref carries the generated
C<password> - a reset is still needed to actually boot into it.

=head2 disable_rescue

    $robot->boot->disable_rescue($server_number);

=head2 linux

    my $linux = $robot->boot->linux($server_number);

Current Linux installation configuration. C<dist> and C<lang> list the
available choices while inactive.

=head2 enable_linux

    my $linux = $robot->boot->enable_linux($server_number,
        dist           => 'Debian 12 minimal',
        lang           => 'en',
        authorized_key => [ 'aa:bb:cc:...' ],   # optional
    );

Arms the unattended Linux installation. The returned hashref carries the
generated C<password>.

=head2 disable_linux

    $robot->boot->disable_linux($server_number);

=head2 vnc

    my $vnc = $robot->boot->vnc($server_number);

Current VNC installation configuration.

=head2 enable_vnc

    my $vnc = $robot->boot->enable_vnc($server_number,
        dist => 'centOS-5.0',
        lang => 'en_US',
    );

=head2 disable_vnc

    $robot->boot->disable_vnc($server_number);

=head2 windows

    my $windows = $robot->boot->windows($server_number);

Current Windows installation configuration.

=head2 enable_windows

    my $windows = $robot->boot->enable_windows($server_number,
        os   => 'Windows Server 2022 Standard Edition',
        lang => 'en',
    );

Requires a previously purchased Windows addon for that server.

=head2 disable_windows

    $robot->boot->disable_windows($server_number);

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Robot> - Main Robot API client

=item * L<WWW::Hetzner::Robot::API::Reset> - Reset API, needed to boot what was armed here

=item * L<WWW::Hetzner::Robot::CLI::Cmd::Boot> - Boot CLI commands

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
