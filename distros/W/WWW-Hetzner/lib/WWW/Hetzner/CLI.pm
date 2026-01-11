package WWW::Hetzner::CLI;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: Hetzner Cloud CLI

use Moo;
use MooX::Cmd;
use MooX::Options;
use WWW::Hetzner::Cloud;

our $VERSION = '0.002';


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
    print "  sshkey           Manage SSH keys\n";
    print "  placement-group  Manage placement groups\n";
    print "\nNetworking:\n";
    print "  network          Manage private networks\n";
    print "  firewall         Manage firewalls\n";
    print "  floating-ip      Manage floating IPs\n";
    print "  primary-ip       Manage primary IPs\n";
    print "  load-balancer    Manage load balancers\n";
    print "\nStorage:\n";
    print "  volume           Manage volumes\n";
    print "\nDNS:\n";
    print "  zone             Manage DNS zones\n";
    print "  record           Manage DNS records\n";
    print "\nSecurity:\n";
    print "  certificate      Manage TLS certificates\n";
    print "\nInfo:\n";
    print "  location         List locations\n";
    print "  datacenter       List datacenters\n";
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

version 0.002

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

=item * server - Manage cloud servers (list, create, delete, describe, poweron, poweroff, reboot, shutdown, reset, rebuild, rescue)

=item * servertype - List server types

=item * image - List images

=item * sshkey - Manage SSH keys (list, create, delete, describe)

=item * placement-group - Manage placement groups (list, create, delete, describe)

=back

=head2 Networking

=over 4

=item * network - Manage private networks (list, create, delete, describe, add-subnet, add-route)

=item * firewall - Manage firewalls (list, create, delete, describe, add-rule, apply-to, remove-from)

=item * floating-ip - Manage floating IPs (list, create, delete, describe, assign, unassign)

=item * primary-ip - Manage primary IPs (list, create, delete, describe, assign, unassign)

=item * load-balancer - Manage load balancers (list, create, delete, describe, add-target, add-service)

=back

=head2 Storage

=over 4

=item * volume - Manage volumes (list, create, delete, describe, attach, detach, resize)

=back

=head2 DNS

=over 4

=item * zone - Manage DNS zones (list, create, delete, describe)

=item * record - Manage DNS records (list, create, delete, describe)

=back

=head2 Security

=over 4

=item * certificate - Manage TLS certificates (list, create, delete, describe)

=back

=head2 Info

=over 4

=item * location - List locations

=item * datacenter - List datacenters

=back

=head2 token

Hetzner Cloud API token. Use C<--token> or C<-t> flag, or set via
C<HETZNER_API_TOKEN> environment variable.

=head2 output

Output format: C<table> (default) or C<json>. Use C<--output> or C<-o> flag.

=head2 cloud

L<WWW::Hetzner::Cloud> instance.

=head2 execute

Main entry point. Shows help when no subcommand is given.

=head1 SEE ALSO

L<WWW::Hetzner::Cloud>

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
