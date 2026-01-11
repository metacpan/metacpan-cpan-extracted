package WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::AddService;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Add a service to a load balancer

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl load-balancer add-service <id> --protocol <proto> --listen-port <port> --destination-port <port>';

option protocol => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Protocol: tcp, http, https',
);

option 'listen_port' => (
    is       => 'ro',
    format   => 'i',
    required => 1,
    long_doc => 'listen-port',
    doc      => 'Listen port',
);

option 'destination_port' => (
    is       => 'ro',
    format   => 'i',
    required => 1,
    long_doc => 'destination-port',
    doc      => 'Destination port',
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl load-balancer add-service <id> --protocol <proto> --listen-port <port> --destination-port <port>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    print "Adding ", $self->protocol, " service to load balancer $id...\n";
    $cloud->load_balancers->add_service($id,
        protocol         => $self->protocol,
        listen_port      => $self->listen_port,
        destination_port => $self->destination_port,
    );
    print "Service added.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::AddService - Add a service to a load balancer

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
