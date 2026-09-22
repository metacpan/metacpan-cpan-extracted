package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Create;
# ABSTRACT: Create a Storage Box

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl storage-box create --name <name> --type <type> --location <location> --password <password> [options]';
use JSON::MaybeXS qw(encode_json);
with 'WWW::Hetzner::CLI::Role::WaitsForAction';


option name => ( is => 'ro', format => 's', required => 1, doc => 'Storage Box name' );
option type => ( is => 'ro', format => 's', required => 1, doc => 'Storage Box type ID or name' );
option location => ( is => 'ro', format => 's', required => 1, doc => 'Location ID or name' );
option password => ( is => 'ro', format => 's', required => 1, doc => 'Storage Box password' );
option label => ( is => 'ro', format => 's@', autosplit => ',', doc => 'Label key=value (repeatable)' );
option ssh_key => ( is => 'ro', format => 's@', autosplit => ',', doc => 'OpenSSH public key (repeatable)' );
option reachable_externally => ( is => 'ro', doc => 'Allow access outside Hetzner networks' );
option enable_samba => ( is => 'ro', doc => 'Enable Samba' );
option enable_ssh => ( is => 'ro', doc => 'Enable SSH' );
option enable_webdav => ( is => 'ro', doc => 'Enable WebDAV' );
option enable_zfs => ( is => 'ro', doc => 'Show the ZFS Snapshot folder' );

sub execute {
    my ($self, $args, $chain) = @_;
    my $main = $chain->[0];
    my %params = (
        name             => $self->name,
        storage_box_type => $self->type,
        location         => $self->location,
        password         => $self->password,
    );

    if ($self->label) {
        my %labels;
        for my $label (@{$self->label}) {
            my ($key, $value) = split /=/, $label, 2;
            die "Label must be key=value\n" unless defined $key && length $key && defined $value;
            $labels{$key} = $value;
        }
        $params{labels} = \%labels;
    }
    $params{ssh_keys} = $self->ssh_key if $self->ssh_key;

    my %access;
    $access{reachable_externally} = $self->reachable_externally if defined $self->reachable_externally;
    $access{samba_enabled} = $self->enable_samba if defined $self->enable_samba;
    $access{ssh_enabled} = $self->enable_ssh if defined $self->enable_ssh;
    $access{webdav_enabled} = $self->enable_webdav if defined $self->enable_webdav;
    $access{zfs_enabled} = $self->enable_zfs if defined $self->enable_zfs;
    $params{access_settings} = \%access if %access;

    print "Creating Storage Box '", $self->name, "'...\n";
    my $box = $main->storage->storage_boxes->create(%params);
    $self->handle_action($box->action);

    if ($main->output eq 'json') {
        print encode_json($box->data), "\n";
        return;
    }
    print "Storage Box created:\n";
    printf "  ID:       %s\n", $box->id;
    printf "  Name:     %s\n", $box->name;
    printf "  Status:   %s\n", $box->status // '-';
    printf "  Username: %s\n", $box->username // '-';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Create - Create a Storage Box

=head1 VERSION

version 0.101

=head1 DESCRIPTION

Creates a Storage Box. Delete protection is configured separately with
C<storage-box enable-protection>; it is not a create option because the
Storage API create request does not accept protection settings.

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
