#!/usr/bin/env perl
# PODNAME: hcloud.pl
# ABSTRACT: Hetzner Cloud CLI (Perl implementation)

use strict;
use warnings;
use lib 'lib';

# Map hyphenated commands to MooX::Cmd package names
# (Perl packages can't have hyphens, so we translate)
my %cmd_aliases = (
    'floating-ip'     => 'floatingip',
    'primary-ip'      => 'primaryip',
    'load-balancer'   => 'loadbalancer',
    'placement-group' => 'placementgroup',
    'add-subnet'      => 'addsubnet',
    'add-route'       => 'addroute',
    'add-rule'        => 'addrule',
    'apply-to'        => 'applyto',
    'remove-from'     => 'removefrom',
    'add-target'      => 'addtarget',
    'add-service'     => 'addservice',
);

for my $i (0 .. $#ARGV) {
    if (exists $cmd_aliases{lc $ARGV[$i]}) {
        $ARGV[$i] = $cmd_aliases{lc $ARGV[$i]};
    }
}

# Custom help for commands with hyphenated subcommands
# (MooX::Cmd shows package names, we want hyphenated names)
my %custom_help = (
    network => sub {
        print "Usage: hcloud.pl network <subcommand>\n\n";
        print "Subcommands:\n";
        print "  list         List all networks\n";
        print "  describe     Show network details\n";
        print "  create       Create a network\n";
        print "  delete       Delete a network\n";
        print "  add-subnet   Add a subnet to network\n";
        print "  add-route    Add a route to network\n";
    },
    firewall => sub {
        print "Usage: hcloud.pl firewall <subcommand>\n\n";
        print "Subcommands:\n";
        print "  list           List all firewalls\n";
        print "  describe       Show firewall details\n";
        print "  create         Create a firewall\n";
        print "  delete         Delete a firewall\n";
        print "  add-rule       Add a rule to firewall\n";
        print "  apply-to       Apply firewall to server\n";
        print "  remove-from    Remove firewall from server\n";
    },
    loadbalancer => sub {
        print "Usage: hcloud.pl load-balancer <subcommand>\n\n";
        print "Subcommands:\n";
        print "  list           List all load balancers\n";
        print "  describe       Show load balancer details\n";
        print "  create         Create a load balancer\n";
        print "  delete         Delete a load balancer\n";
        print "  add-target     Add a target to load balancer\n";
        print "  add-service    Add a service to load balancer\n";
    },
);

# Check if help was requested for a command with custom help
# Only intercept if: command --help (not: command subcommand --help)
if (@ARGV >= 1) {
    my $cmd = lc $ARGV[0];
    $cmd =~ s/-//g;  # normalize: load-balancer -> loadbalancer
    if (exists $custom_help{$cmd}) {
        # Check second arg: is it --help or a subcommand?
        my $second = $ARGV[1] // '';
        if ($second =~ /^(-h|--help|--usage|--man)$/) {
            $custom_help{$cmd}->();
            exit 0;
        }
    }
}

use WWW::Hetzner::CLI;

WWW::Hetzner::CLI->new_with_cmd;

__END__

=pod

=encoding UTF-8

=head1 NAME

hcloud.pl - Hetzner Cloud CLI (Perl implementation)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    # List servers
    hcloud.pl server

    # Create a server (minimal)
    hcloud.pl server create --name my-server --type cx22 --image debian-12

    # Create a server (full options)
    hcloud.pl server create \
        --name my-server \
        --type cx22 \
        --image debian-12 \
        --location fsn1 \
        --ssh-key my-key \
        --label env=prod \
        --label team=ops \
        --user-data-from-file cloud-init.yaml

    # Create without public IPv4
    hcloud.pl server create --name private-server --type cx22 --image debian-12 \
        --without-ipv4 --network 12345

    # Delete a server
    hcloud.pl server delete 12345

    # Describe a server
    hcloud.pl server describe 12345

    # List server types
    hcloud.pl servertype

    # JSON output
    hcloud.pl -o json server

=head1 DESCRIPTION

Perl implementation of the Hetzner Cloud CLI tool (hcloud). This script
provides a command-line interface to the Hetzner Cloud API.

To avoid conflicts with the official hcloud binary, this script is named
C<hcloud.pl>. You can create an alias if desired:

    alias hcloud='perl /path/to/hcloud.pl'

=head1 NAME

hcloud.pl - Hetzner Cloud CLI (Perl implementation)

=head1 OPTIONS

=over 4

=item B<-t>, B<--token>=TOKEN

Hetzner Cloud API token. Defaults to C<HETZNER_API_TOKEN> environment variable.

=item B<-o>, B<--output>=FORMAT

Output format: C<table> (default) or C<json>.

=back

=head1 COMMANDS

=head2 server

Manage servers.

=head3 server create

Create a new server. Required options: C<--name>, C<--type>, C<--image>.

    hcloud.pl server create --name web1 --type cx22 --image debian-12

Options:

    --name              Server name (required)
    --type              Server type, e.g., cx22, cpx11 (required)
    --image             Image name, e.g., debian-12 (required)
    --location          Location: fsn1, nbg1, hel1, ash, hil
    --datacenter        Datacenter, e.g., fsn1-dc14
    --ssh-key           SSH key name or ID (repeatable)
    --label             Label as key=value (repeatable)
    --network           Network ID to attach (repeatable)
    --volume            Volume ID to attach (repeatable)
    --firewall          Firewall ID (repeatable)
    --placement-group   Placement group ID or name
    --user-data-from-file   Path to cloud-init file
    --without-ipv4      Create without public IPv4
    --without-ipv6      Create without public IPv6
    --primary-ipv4      Assign existing Primary IPv4
    --primary-ipv6      Assign existing Primary IPv6
    --automount         Automount attached volumes
    --no-start-after-create  Don't start server after creation

=head3 server list

List all servers.

=head3 server describe <ID>

Show details for a server.

=head3 server delete <ID>

Delete a server.

=head2 sshkey

Manage SSH keys.

=head2 image

List images. Use C<--type> to filter by type (system, snapshot, backup).

=head2 servertype

List available server types.

=head2 location

List available locations.

=head2 datacenter

List available datacenters.

=head1 ENVIRONMENT

=over 4

=item C<HETZNER_API_TOKEN>

Default API token if not specified via C<--token>.

=back

=head1 SEE ALSO

L<WWW::Hetzner::CLI>, L<WWW::Hetzner::Cloud>, L<https://docs.hetzner.cloud/>

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
