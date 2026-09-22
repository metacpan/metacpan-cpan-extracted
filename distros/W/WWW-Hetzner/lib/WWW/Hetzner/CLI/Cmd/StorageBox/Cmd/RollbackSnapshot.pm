package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::RollbackSnapshot;
# ABSTRACT: Roll a Storage Box back to a snapshot

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl storage-box rollback-snapshot --snapshot <id> <storage-box>';
with 'WWW::Hetzner::CLI::Role::WaitsForAction';


option snapshot => (
    is       => 'ro',
    format   => 'i',
    required => 1,
    doc      => 'Snapshot ID to roll back to',
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl storage-box rollback-snapshot --snapshot <id> <storage-box>\n";
    my $action = $chain->[0]->storage->storage_boxes->rollback_snapshot($id, snapshot => $self->snapshot);
    $self->handle_action($action);
    print $self->no_wait ? "Storage Box rollback requested.\n" : "Storage Box rolled back to snapshot.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::RollbackSnapshot - Roll a Storage Box back to a snapshot

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl storage-box rollback-snapshot 42 --snapshot 1
    hcloud.pl storage-box rollback-snapshot 42 --snapshot 1 --no-wait

=head1 DESCRIPTION

Rolls a Storage Box back to the contents of an existing snapshot.

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
