package WWW::Hetzner::CLI::Cmd::Network::Cmd::AddSubnet;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Add a subnet to a network

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl network add-subnet <id> --ip-range <cidr> --type <type> --network-zone <zone>';

option 'ip_range' => (
    is       => 'ro',
    format   => 's',
    required => 1,
    long_doc => 'ip-range',
    doc      => 'Subnet IP range (e.g. 10.0.1.0/24)',
);

option type => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Subnet type: cloud, server, vswitch',
);

option 'network_zone' => (
    is       => 'ro',
    format   => 's',
    required => 1,
    long_doc => 'network-zone',
    doc      => 'Network zone (e.g. eu-central)',
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl network add-subnet <id> --ip-range <cidr> --type <type> --network-zone <zone>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    print "Adding subnet ", $self->ip_range, " to network $id...\n";
    $cloud->networks->add_subnet($id,
        ip_range     => $self->ip_range,
        type         => $self->type,
        network_zone => $self->network_zone,
    );
    print "Subnet added.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Network::Cmd::AddSubnet - Add a subnet to a network

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
