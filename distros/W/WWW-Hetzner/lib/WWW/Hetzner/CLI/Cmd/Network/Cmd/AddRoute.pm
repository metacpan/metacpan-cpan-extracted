package WWW::Hetzner::CLI::Cmd::Network::Cmd::AddRoute;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Add a route to a network

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl network add-route <id> --destination <cidr> --gateway <ip>';

option destination => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Route destination (e.g. 10.100.0.0/16)',
);

option gateway => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Gateway IP address',
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl network add-route <id> --destination <cidr> --gateway <ip>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    print "Adding route ", $self->destination, " via ", $self->gateway, " to network $id...\n";
    $cloud->networks->add_route($id,
        destination => $self->destination,
        gateway     => $self->gateway,
    );
    print "Route added.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Network::Cmd::AddRoute - Add a route to a network

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
