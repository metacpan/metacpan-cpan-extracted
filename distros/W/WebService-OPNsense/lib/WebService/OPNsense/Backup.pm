#!/bin/false
# ABSTRACT: Backup controller
# PODNAME: WebService::OPNsense::Backup
use strictures 2;

package WebService::OPNsense::Backup;
$WebService::OPNsense::Backup::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/core/backup';
}

with 'WebService::OPNsense::Role::APIPath';

sub backups {
    my ( $self, $host ) = @_;
    return $self->client->get( $self->_path( 'backups/{host}', host => $host ) );
}

sub download {
    my ( $self, $host, $backup ) = @_;
    my $path = $self->_path( 'download/{host}{/backup}', host => $host, backup => $backup );
    return $self->client->get($path);
}

sub diff {
    my ( $self, $host, $backup1, $backup2 ) = @_;
    return $self->client->get(
        $self->_path( 'diff/{host}/{backup1}/{backup2}', host => $host, backup1 => $backup1, backup2 => $backup2 ),
    );
}

sub providers {
    my ($self) = @_;
    return $self->client->get( $self->_path('providers') );
}

sub delete_backup {
    my ( $self, $backup ) = @_;
    return $self->client->post( $self->_path( 'deleteBackup/{backup}', backup => $backup ) );
}

sub revert_backup {
    my ( $self, $backup ) = @_;
    return $self->client->post( $self->_path( 'revertBackup/{backup}', backup => $backup ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Backup - Backup controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $backup = $opn->backup;

    my $backups = $backup->backups($host);

=head1 DESCRIPTION

Manages configuration backups.

=head1 NAME

WebService::OPNsense::Backup - Backup controller

=head1 METHODS

=head2 backups

    my $backups = $backup->backups($host);

Lists backups for a given host.

=head2 download

    my $data = $backup->download($host);
    my $data = $backup->download($host, $backup);

Downloads a backup.  Optionally specify a specific backup revision.

=head2 diff

    my $diff = $backup->diff($host, $backup1, $backup2);

Returns the diff between two backup revisions.

=head2 providers

    my $providers = $backup->providers;

Lists backup providers.

=head2 delete_backup

    my $result = $backup->delete_backup($backup);

Deletes a backup.

=head2 revert_backup

    my $result = $backup->revert_backup($backup);

Reverts to a backup.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
