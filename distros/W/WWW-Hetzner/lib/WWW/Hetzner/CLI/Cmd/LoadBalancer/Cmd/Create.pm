package WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::Create;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Create a load balancer

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl load-balancer create --name <name> --type <type> --location <loc>';

option name => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Load balancer name',
);

option type => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Load balancer type (e.g. lb11)',
);

option location => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Location (e.g. fsn1)',
);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    print "Creating load balancer '", $self->name, "'...\n";
    my $lb = $cloud->load_balancers->create(
        name               => $self->name,
        load_balancer_type => $self->type,
        location           => $self->location,
    );
    print "Load balancer created with ID ", $lb->id, "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::Create - Create a load balancer

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
