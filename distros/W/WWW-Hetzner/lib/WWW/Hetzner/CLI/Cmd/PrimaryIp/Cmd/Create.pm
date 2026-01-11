package WWW::Hetzner::CLI::Cmd::PrimaryIp::Cmd::Create;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Create a primary IP

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl primary-ip create --name <name> --type <ipv4|ipv6> --datacenter <dc>';

option name => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Primary IP name',
);

option type => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'IP type: ipv4 or ipv6',
);

option datacenter => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Datacenter (e.g. fsn1-dc14)',
);

option 'auto_delete' => (
    is       => 'ro',
    long_doc => 'auto-delete',
    doc      => 'Auto delete when server is deleted',
);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    print "Creating primary IP...\n";
    my $pip = $cloud->primary_ips->create(
        name          => $self->name,
        type          => $self->type,
        assignee_type => 'server',
        datacenter    => $self->datacenter,
        ($self->auto_delete ? (auto_delete => 1) : ()),
    );
    print "Primary IP created with ID ", $pip->id, " (", $pip->ip, ")\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::PrimaryIp::Cmd::Create - Create a primary IP

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
