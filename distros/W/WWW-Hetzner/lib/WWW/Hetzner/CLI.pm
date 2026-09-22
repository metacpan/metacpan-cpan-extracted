package WWW::Hetzner::CLI;

# ABSTRACT: Hetzner Cloud CLI

use Moo;
use MooX::Cmd;
use MooX::Options;
use WWW::Hetzner::Cloud;
use WWW::Hetzner::Storage;

our $VERSION = '0.101';


option token => (
    is     => 'ro',
    format => 's',
    short  => 't',
    doc    => 'API token (default: HETZNER_API_TOKEN env)',
    default => sub { $ENV{HETZNER_API_TOKEN} },
);


option output => (
    is      => 'ro',
    format  => 's',
    short   => 'o',
    doc     => 'Output format: table, json (default: table)',
    default => 'table',
);


has cloud => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;
        WWW::Hetzner::Cloud->new(token => $self->token);
    },
);


has storage => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;
        WWW::Hetzner::Storage->new(token => $self->token);
    },
);


sub execute {
    my ($self, $args, $chain) = @_;

    # No subcommand given, show help
    print "Usage: hcloud.pl [options] <command> [command-options]\n\n";
    print "Global options (must come BEFORE the command):\n";
    print "  -t, --token    API token\n";
    print "  -o, --output   Output format: table, json\n";
    print "\nServer & Compute:\n";
    print "  server           Manage cloud servers\n";
    print "  servertype       List server types\n";
    print "  image            List images\n";
    print "  iso              List ISOs\n";
    print "  sshkey           Manage SSH keys\n";
    print "  placement-group  Manage placement groups\n";
    print "\nNetworking:\n";
    print "  network          Manage private networks\n";
    print "  firewall         Manage firewalls\n";
    print "  floating-ip      Manage floating IPs\n";
    print "  primary-ip       Manage primary IPs\n";
    print "  load-balancer    Manage load balancers\n";
    print "  load-balancer-type  List load balancer types\n";
    print "\nStorage:\n";
    print "  volume           Manage volumes\n";
    print "  storage-box      Manage Storage Boxes\n";
    print "\nDNS:\n";
    print "  zone             Manage DNS zones\n";
    print "  record           Manage DNS records\n";
    print "\nSecurity:\n";
    print "  certificate      Manage TLS certificates\n";
    print "\nInfo:\n";
    print "  location         List locations\n";
    print "  datacenter       List datacenters\n";
    print "  pricing          Show the current price list\n";
    print "\nExamples:\n";
    print "  hcloud.pl server list\n";
    print "  hcloud.pl -t mytoken server list\n";
    print "  hcloud.pl --output json server describe 12345\n";
    print "  hcloud.pl volume create --name data --size 50 --location fsn1\n";
    print "  hcloud.pl firewall create --name web-fw\n";
    print "\nEnvironment variables:\n";
    print "  HETZNER_API_TOKEN  Default for --token\n";
    print "\nRun 'hcloud.pl <command> --help' for command-specific options.\n";
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI - Hetzner Cloud CLI

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::CLI;
    WWW::Hetzner::CLI->new_with_cmd;

=head1 DESCRIPTION

Main CLI class for the Hetzner Cloud API client. Uses L<MooX::Cmd>
for subcommand handling.

This CLI is designed to be a B<1:1 replica> of the official C<hcloud> CLI
from Hetzner (L<https://github.com/hetznercloud/cli>). Command structure,
options, and output should match the original tool as closely as possible.

=head1 COMMANDS

=head2 Server & Compute

=over 4

=item * L<server|WWW::Hetzner::CLI::Cmd::Server> - Manage cloud servers

=item * L<servertype|WWW::Hetzner::CLI::Cmd::Servertype> - List server types

=item * L<image|WWW::Hetzner::CLI::Cmd::Image> - List images

=item * L<iso|WWW::Hetzner::CLI::Cmd::Iso> - List ISOs

=item * L<sshkey|WWW::Hetzner::CLI::Cmd::Sshkey> - Manage SSH keys

=item * L<placement-group|WWW::Hetzner::CLI::Cmd::PlacementGroup> - Manage placement groups

=back

=head2 Networking

=over 4

=item * L<network|WWW::Hetzner::CLI::Cmd::Network> - Manage private networks

=item * L<firewall|WWW::Hetzner::CLI::Cmd::Firewall> - Manage firewalls

=item * L<floating-ip|WWW::Hetzner::CLI::Cmd::FloatingIp> - Manage floating IPs

=item * L<primary-ip|WWW::Hetzner::CLI::Cmd::PrimaryIp> - Manage primary IPs

=item * L<load-balancer|WWW::Hetzner::CLI::Cmd::LoadBalancer> - Manage load balancers

=item * L<load-balancer-type|WWW::Hetzner::CLI::Cmd::LoadBalancerType> - List load balancer types

=back

=head2 Storage

=over 4

=item * L<volume|WWW::Hetzner::CLI::Cmd::Volume> - Manage volumes

=item * L<storage-box|WWW::Hetzner::CLI::Cmd::StorageBox> - Manage Storage Boxes

=back

=head2 DNS

=over 4

=item * L<zone|WWW::Hetzner::CLI::Cmd::Zone> - Manage DNS zones

=item * L<record|WWW::Hetzner::CLI::Cmd::Record> - Manage DNS records

=back

=head2 Security

=over 4

=item * L<certificate|WWW::Hetzner::CLI::Cmd::Certificate> - Manage TLS certificates

=back

=head2 Info

=over 4

=item * L<location|WWW::Hetzner::CLI::Cmd::Location> - List locations

=item * L<datacenter|WWW::Hetzner::CLI::Cmd::Datacenter> - List datacenters

=item * L<pricing|WWW::Hetzner::CLI::Cmd::Pricing> - Show the current price list

=back

=head2 token

Hetzner Cloud API token. Use C<--token> or C<-t> flag, or set via
C<HETZNER_API_TOKEN> environment variable.

=head2 output

Output format: C<table> (default) or C<json>. Use C<--output> or C<-o> flag.

=head2 cloud

L<WWW::Hetzner::Cloud> instance.

=head2 storage

L<WWW::Hetzner::Storage> instance, configured from the same C<--token>
option as the Cloud client.

=head2 execute

Main entry point. Shows help when no subcommand is given.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner> - Main umbrella module

=item * L<WWW::Hetzner::Cloud> - Cloud API client

=item * L<WWW::Hetzner::Storage> - Storage Box API client

=item * L<https://docs.hetzner.cloud/> - Official Hetzner Cloud API documentation

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
