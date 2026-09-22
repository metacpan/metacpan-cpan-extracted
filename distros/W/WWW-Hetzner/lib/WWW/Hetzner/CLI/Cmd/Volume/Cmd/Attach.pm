package WWW::Hetzner::CLI::Cmd::Volume::Cmd::Attach;
# ABSTRACT: Attach a volume to a server

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl volume attach <volume-id> --server <server-id>';
with 'WWW::Hetzner::CLI::Role::WaitsForAction';

option server => (
    is       => 'ro',
    format   => 'i',
    required => 1,
    doc      => 'Server ID to attach to',
);

option automount => (
    is      => 'ro',
    doc     => 'Automount volume after attach',
    default => 0,
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl volume attach <volume-id> --server <server-id>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    print "Attaching volume $id to server ", $self->server, "...\n";
    my $action = $cloud->volumes->attach($id, $self->server, automount => $self->automount);
    $self->handle_action($action);
    print $self->no_wait ? "Volume attach requested.\n" : "Volume attached.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Volume::Cmd::Attach - Attach a volume to a server

=head1 VERSION

version 0.101

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
