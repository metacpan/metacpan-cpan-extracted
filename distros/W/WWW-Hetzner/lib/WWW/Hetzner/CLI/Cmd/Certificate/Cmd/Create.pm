package WWW::Hetzner::CLI::Cmd::Certificate::Cmd::Create;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Create a managed certificate

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl certificate create --name <name> --domain <domain> [--domain <domain>...]';

option name => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Certificate name',
);

option domain => (
    is       => 'ro',
    format   => 's@',
    required => 1,
    doc      => 'Domain name (can specify multiple)',
);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    print "Creating managed certificate '", $self->name, "'...\n";
    my $cert = $cloud->certificates->create(
        name         => $self->name,
        type         => 'managed',
        domain_names => $self->domain,
    );
    print "Certificate created with ID ", $cert->id, "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Certificate::Cmd::Create - Create a managed certificate

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
