package WWW::Hetzner::CLI::Cmd::Server::Cmd::Create;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Create a server

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl server create --name <name> --type <type> --image <image> [options]';
use JSON::MaybeXS qw(encode_json);
use Path::Tiny qw(path);

# Required options
option name => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Server name',
);

option type => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Server type (e.g., cx22, cx32, cpx11)',
);

option image => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Image (e.g., debian-12, ubuntu-24.04)',
);

# Location options (mutually exclusive)
option location => (
    is     => 'ro',
    format => 's',
    doc    => 'Location (e.g., fsn1, nbg1, hel1, ash, hil)',
);

option datacenter => (
    is     => 'ro',
    format => 's',
    doc    => 'Datacenter (e.g., fsn1-dc14)',
);

# SSH and security
option ssh_key => (
    is        => 'ro',
    format    => 's@',
    doc       => 'SSH key name or ID (repeatable)',
    autosplit => ',',
);

option firewall => (
    is        => 'ro',
    format    => 's@',
    doc       => 'Firewall ID (repeatable)',
    autosplit => ',',
);

# Labels
option label => (
    is        => 'ro',
    format    => 's@',
    doc       => 'Labels (key=value, repeatable)',
    autosplit => ',',
);

# Network options
option network => (
    is        => 'ro',
    format    => 's@',
    doc       => 'Network ID to attach (repeatable)',
    autosplit => ',',
);

option without_ipv4 => (
    is      => 'ro',
    doc     => 'Create without public IPv4',
    default => 0,
);

option without_ipv6 => (
    is      => 'ro',
    doc     => 'Create without public IPv6',
    default => 0,
);

option primary_ipv4 => (
    is     => 'ro',
    format => 's',
    doc    => 'Primary IPv4 ID or IP to assign',
);

option primary_ipv6 => (
    is     => 'ro',
    format => 's',
    doc    => 'Primary IPv6 ID or IP to assign',
);

# Storage
option volume => (
    is        => 'ro',
    format    => 's@',
    doc       => 'Volume ID to attach (repeatable)',
    autosplit => ',',
);

option automount => (
    is      => 'ro',
    doc     => 'Automount volumes after attach',
    default => 0,
);

# Placement
option placement_group => (
    is     => 'ro',
    format => 's',
    doc    => 'Placement group ID or name',
);

# User data
option user_data_from_file => (
    is     => 'ro',
    format => 's',
    doc    => 'Read cloud-init user data from file',
);

# Startup
option start_after_create => (
    is      => 'ro',
    doc     => 'Start server after create (default: true)',
    default => 1,
    negativable => 1,
);

option allow_deprecated_image => (
    is      => 'ro',
    doc     => 'Allow deprecated images',
    default => 0,
);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my %params = (
        name        => $self->name,
        server_type => $self->type,
        image       => $self->image,
    );

    # Location/Datacenter
    $params{location}   = $self->location   if $self->location;
    $params{datacenter} = $self->datacenter if $self->datacenter;

    # SSH Keys
    $params{ssh_keys} = $self->ssh_key if $self->ssh_key;

    # Firewalls
    $params{firewalls} = $self->firewall if $self->firewall;

    # Labels
    if ($self->label) {
        my %labels;
        for my $l (@{$self->label}) {
            my ($k, $v) = split /=/, $l, 2;
            $labels{$k} = $v;
        }
        $params{labels} = \%labels;
    }

    # Networks
    $params{networks} = $self->network if $self->network;

    # IPv4/IPv6 options
    $params{enable_ipv4} = 0 if $self->without_ipv4;
    $params{enable_ipv6} = 0 if $self->without_ipv6;
    $params{ipv4} = $self->primary_ipv4 if $self->primary_ipv4;
    $params{ipv6} = $self->primary_ipv6 if $self->primary_ipv6;

    # Volumes
    $params{volumes}   = $self->volume if $self->volume;
    $params{automount} = 1 if $self->automount;

    # Placement group
    $params{placement_group} = $self->placement_group if $self->placement_group;

    # User data
    if ($self->user_data_from_file) {
        $params{user_data} = path($self->user_data_from_file)->slurp_utf8;
    }

    # Startup
    $params{start_after_create} = $self->start_after_create;

    print "Creating server '$params{name}'...\n";

    my $server = $cloud->servers->create(%params);

    if ($main->output eq 'json') {
        print encode_json($server->data), "\n";
        return;
    }

    print "Server created:\n";
    printf "  ID:         %s\n", $server->id;
    printf "  Name:       %s\n", $server->name;
    printf "  Status:     %s\n", $server->status;
    printf "  IPv4:       %s\n", $server->ipv4 // 'none';
    printf "  IPv6:       %s\n", $server->ipv6 // 'none';
    printf "  Datacenter: %s\n", $server->datacenter // '-';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Server::Cmd::Create - Create a server

=head1 VERSION

version 0.002

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
