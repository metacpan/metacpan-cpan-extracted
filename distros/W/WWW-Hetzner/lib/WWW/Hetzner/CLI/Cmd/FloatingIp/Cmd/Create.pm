package WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Create;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Create a floating IP

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl floating-ip create --type <ipv4|ipv6> --home-location <location>';

option type => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'IP type: ipv4 or ipv6',
);

option 'home_location' => (
    is       => 'ro',
    format   => 's',
    required => 1,
    long_doc => 'home-location',
    doc      => 'Home location (e.g. fsn1, nbg1)',
);

option name => (
    is     => 'ro',
    format => 's',
    doc    => 'Floating IP name',
);

option description => (
    is     => 'ro',
    format => 's',
    doc    => 'Description',
);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    print "Creating floating IP...\n";
    my $fip = $cloud->floating_ips->create(
        type          => $self->type,
        home_location => $self->home_location,
        ($self->name        ? (name        => $self->name)        : ()),
        ($self->description ? (description => $self->description) : ()),
    );
    print "Floating IP created with ID ", $fip->id, " (", $fip->ip, ")\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Create - Create a floating IP

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
