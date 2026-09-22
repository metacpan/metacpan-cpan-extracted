package WWW::Hetzner::CLI::Cmd::StorageBox;
# ABSTRACT: Storage Box commands

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl storage-box <command> [options]';
use JSON::MaybeXS qw(encode_json);


option name => (
    is     => 'ro',
    format => 's',
    short  => 'n',
    doc    => 'Filter by Storage Box name',
);

option selector => (
    is     => 'ro',
    format => 's',
    short  => 'l',
    doc    => 'Filter by label selector',
);

sub execute {
    my ($self, $args, $chain) = @_;
    $self->_list($chain);
}

sub _list {
    my ($self, $chain) = @_;
    my $main = $chain->[0];
    my %params;
    $params{name} = $self->name if defined $self->name;
    $params{label_selector} = $self->selector if defined $self->selector;
    my $boxes = $main->storage->storage_boxes->list_all(%params);

    if ($main->output eq 'json') {
        print encode_json([map { $_->data } @$boxes]), "\n";
        return;
    }

    if (!@$boxes) {
        print "No Storage Boxes found.\n";
        return;
    }

    printf "%-10s %-25s %-12s %-12s %s\n", 'ID', 'NAME', 'TYPE', 'LOCATION', 'STATUS';
    print '-' x 78, "\n";
    for my $box (@$boxes) {
        my $type = $box->storage_box_type;
        my $location = $box->location;
        printf "%-10s %-25s %-12s %-12s %s\n",
            $box->id,
            $box->name,
            ref $type eq 'HASH' ? ($type->{name} // '-') : ($type // '-'),
            ref $location eq 'HASH' ? ($location->{name} // '-') : ($location // '-'),
            $box->status // '-';
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox - Storage Box commands

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl storage-box list
    hcloud.pl storage-box create --name archive --type bx11 --location fsn1 --password secret
    hcloud.pl storage-box snapshot list 123
    hcloud.pl storage-box subaccount list 123

=head1 DESCRIPTION

Manage Hetzner Storage Boxes, their snapshots, and their subaccounts.

=head1 SUBCOMMANDS

=over 4

=item * L<list|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::List>

=item * L<describe|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Describe>

=item * L<create|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Create>

=item * L<update|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Update>

=item * L<delete|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Delete>

=item * L<change-type|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::ChangeType>

=item * L<reset-password|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::ResetPassword>

=item * L<enable-protection|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::EnableProtection>

=item * L<disable-protection|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::DisableProtection>

=item * L<enable-snapshot-plan|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::EnableSnapshotPlan>

=item * L<disable-snapshot-plan|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::DisableSnapshotPlan>

=item * L<rollback-snapshot|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::RollbackSnapshot>

=item * L<update-access-settings|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::UpdateAccessSettings>

=item * L<folders|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Folders>

=item * L<add-label|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::AddLabel>

=item * L<remove-label|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::RemoveLabel>

=item * L<snapshot|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot>

=item * L<subaccount|WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount>

=back

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::CLI> - Main CLI

=item * L<WWW::Hetzner::Storage> - Storage Box API client

=item * L<https://github.com/hetznercloud/cli/tree/main/docs/reference/manual> - Official hcloud CLI manual

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
