package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::UpdateAccessSettings;
# ABSTRACT: Update Storage Box subaccount access settings

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl storage-box subaccount update-access-settings [options] <storage-box> <subaccount>';
use WWW::Hetzner::Storage::API::Subaccounts;
with 'WWW::Hetzner::CLI::Role::WaitsForAction';


option enable_samba => ( is => 'ro', negativable => 1, doc => 'Enable Samba' );
option enable_ssh => ( is => 'ro', negativable => 1, doc => 'Enable SSH' );
option enable_webdav => ( is => 'ro', negativable => 1, doc => 'Enable WebDAV' );
option reachable_externally => ( is => 'ro', negativable => 1, doc => 'Allow access outside Hetzner networks' );
option readonly => ( is => 'ro', negativable => 1, doc => 'Mark the subaccount as read-only' );

sub execute {
    my ($self, $args, $chain) = @_;
    my $id  = $args->[0] or die "Usage: hcloud.pl storage-box subaccount update-access-settings <storage-box> <subaccount>\n";
    my $sub = $args->[1] or die "Usage: hcloud.pl storage-box subaccount update-access-settings <storage-box> <subaccount>\n";

    my %body;
    $body{samba_enabled} = $self->enable_samba if defined $self->enable_samba;
    $body{ssh_enabled} = $self->enable_ssh if defined $self->enable_ssh;
    $body{webdav_enabled} = $self->enable_webdav if defined $self->enable_webdav;
    $body{reachable_externally} = $self->reachable_externally if defined $self->reachable_externally;
    $body{readonly} = $self->readonly if defined $self->readonly;

    my $subaccounts = WWW::Hetzner::Storage::API::Subaccounts->new(
        client         => $chain->[0]->storage,
        storage_box_id => $id,
    );
    my $action = $subaccounts->update_access_settings($sub, %body);
    $self->handle_action($action);
    print $self->no_wait ? "Subaccount access settings update requested.\n" : "Subaccount access settings updated.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::UpdateAccessSettings - Update Storage Box subaccount access settings

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl storage-box subaccount update-access-settings 42 1 --enable-ssh --readonly

=head1 DESCRIPTION

Updates the access settings of a subaccount. Only the flags explicitly
set on the command line are sent in the request body. Polls the action
by default unless C<--no-wait> is given.

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
