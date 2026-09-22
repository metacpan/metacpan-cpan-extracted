package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot;
# ABSTRACT: Storage Box snapshot commands

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl storage-box snapshot <command> [options] <storage-box>';
use JSON::MaybeXS qw(encode_json);
use WWW::Hetzner::Storage::API::Snapshots;


sub execute {
    my ($self, $args, $chain) = @_;
    $self->_list($args, $chain);
}

sub _list {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl storage-box snapshot list <storage-box>\n";
    my $main = $chain->[0];
    my $snapshots = WWW::Hetzner::Storage::API::Snapshots->new(
        client         => $main->storage,
        storage_box_id => $id,
    )->list;

    if ($main->output eq 'json') {
        print encode_json([map { $_->data } @$snapshots]), "\n";
        return;
    }

    if (!@$snapshots) {
        print "No snapshots found.\n";
        return;
    }

    printf "%-10s %-30s %-25s %s\n", 'ID', 'NAME', 'DESCRIPTION', 'CREATED';
    print '-' x 90, "\n";
    for my $snap (@$snapshots) {
        printf "%-10s %-30s %-25s %s\n",
            $snap->id,
            $snap->name // '-',
            ($snap->description // '') ne '' ? $snap->description : '-',
            $snap->created // '-';
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot - Storage Box snapshot commands

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl storage-box snapshot list 42
    hcloud.pl storage-box snapshot describe 42 1
    hcloud.pl storage-box snapshot create 42 --description "before upgrade"
    hcloud.pl storage-box snapshot delete 42 1

=head1 DESCRIPTION

Manage snapshots of a single Storage Box. Without an explicit subcommand,
the snapshot list for the given Storage Box is shown.

=head1 SUBCOMMANDS

=over 4

=item * L<list|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::List>

=item * L<describe|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::Describe>

=item * L<create|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::Create>

=item * L<update|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::Update>

=item * L<delete|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::Delete>

=item * L<add-label|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::AddLabel>

=item * L<remove-label|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::RemoveLabel>

=back

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::CLI::Cmd::StorageBox> - Parent Storage Box command tree

=item * L<WWW::Hetzner::Storage::Snapshot> - Snapshot entity

=back

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
