package Zucchini::Rsync;
$Zucchini::Rsync::VERSION = '0.0.21';
{
  $Zucchini::Rsync::DIST = 'Zucchini';
}
# ABSTRACT: move files using rsync
# vim: ts=8 sts=4 et sw=4 sr sta
use Moo;
use strict; # for kwalitee testing
use Zucchini::Types qw(:all);

use Carp;
use Config::Any;
use File::Rsync;

# class data
has config => (
    reader  => 'get_config',
    writer  => 'set_config',
    isa     => ZucchiniConfig,
    is      => 'ro',
);

sub remote_sync {
    my $self = shift;

    my $config      = $self->get_config->get_siteconfig();
    my $local_dir   = $config->{output_dir};
    my $rsync_data  = $config->{rsync};

    # we need a remote host and a path
    foreach my $required (qw[ hostname path ]) {
        if (not exists $rsync_data->{$required}) {
            warn "missing rsync option '$required'. rsync aborted\n";
            return;
        }
    }

    # create a new rsync object
    my $syncer = File::Rsync->new(
        {
            recursive       => 1,
            compress        => 1,
            verbose         => $self->get_config->verbose(2),
            'dry-run'       => $self->get_config->is_dry_run() || 0,
        }
    );

    # make sure it was successfully created
    if (not defined $syncer) {
        warn "Can't create File::Rsync object\n";
        return;
    }

    # perform the rsync operation
    if ($self->get_config->verbose) {
        if ($self->get_config->is_dry_run()) {
            warn "Running rsync in dryrun mode\n";
        }
        warn "Starting rsync\n";
    }
    $syncer->exec(
        {
            src     => "$local_dir/",
            dest    => "$rsync_data->{hostname}:$rsync_data->{path}/",
        }
    );

    # give feedback if we're verbose
    if ($self->get_config->verbose(2)) {
        warn $syncer->out();
    }
    if ($self->get_config->verbose) {
        warn "Completed rsync\n";
    }

    # give feedback if there were any errors
    if ($syncer->err()) {
        warn $syncer->err();
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Zucchini::Rsync - move files using rsync

=head1 VERSION

version 0.0.21

=head1 SYNOPSIS

  # create a new rsync object
  $rsyncer = Zucchini::Rsync->new(
    {
      config => $self->get_config,
    }
  );

  # transfer the site
  $rsyncer->remote_sync;

=head1 DESCRIPTION

This module implements the functionality to transfer files to the remote site
using FTP.

=head1 METHODS

=head2 new

Creates a new instance of the Zucchini Rsync object:

  # create a new fsync object
  $rsyncer = Zucchini::Rsync->new(
    {
      config => $zucchini->get_config,
    }
  );

=head2 remote_sync

This function performs an upload to the remote server using File::Rsync.

  # transfer the site
  $rsyncer->remote_sync;

=head1 SEE ALSO

L<Zucchini>

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
