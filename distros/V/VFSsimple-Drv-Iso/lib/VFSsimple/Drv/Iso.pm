package VFSsimple::Drv::Iso;

use strict;
use warnings;
use Device::Cdio::ISO9660;
use Device::Cdio::ISO9660::IFS ();
use File::Temp qw(tempfile);
use POSIX;
use base qw(VFSsimple::Base);

our $VERSION = '0.03';

=head1 NAME

VFSsimple::Drv::Iso - A VFSsimple implementation over ISO9660 fs

=head1 DESCRIPTION

This module provide access method for VFSsimple module to access to files
inside ISO9660 CD image.

Access is provide using L<Device::Cdio::ISO9660> module.

=cut

sub drv_new {
    my ($self) = @_;
    my $iso = Device::Cdio::ISO9660::IFS->new(-source => $self->archive_path);
    $self->{iso} = $iso or return;
    $self->{prefix} = $self->archive_subpath || '';

    return $iso ? $self : ();
}

sub drv_copy {
    my ($self, $src, $dest) = @_;
    open(my $fh, '>', $dest) or return;
    my $iso = $self->{iso};
    my $stat = $iso->stat("$self->{prefix}/$src", 0) or return;
    if ($stat) {
        my $blocks = POSIX::ceil($stat->{size} / $perlcdio::ISO_BLOCKSIZE);
        for (my $i = 0; $i < $blocks; $i++) {
            my $lsn = $stat->{LSN} + $i;
            my $buf = $iso->seek_read ($lsn);
            if (defined($buf)) {
                print $fh (($i + 1) * $perlcdio::ISO_BLOCKSIZE > $stat->{size}) ?
                    substr($buf, 0, $stat->{size} - ($i + 1) * $perlcdio::ISO_BLOCKSIZE) :
                    $buf;

            } else {
                return;
            }
        }
    }
    close($fh);
    return $dest;
}

sub drv_stat {
    my ($self, $file) = @_;
    my $iso = $self->{iso};
    return(defined($iso->stat("$self->{prefix}/$file", 0)));
}

1;

__END__

=head1 SEE ALSO

L<VFSsimple>

=head1 LICENSE AND COPYRIGHT

(c) 2006, 2007 Olivier Thauvin <nanardon@nanardon.zarb.org>

/* This program is free software. It comes without any warranty, to
 * the extent permitted by applicable law. You can redistribute it
 * and/or modify it under the terms of the Do What The Fuck You Want
 * To Public License, Version 2, as published by Sam Hocevar. See
 * http://sam.zoy.org/wtfpl/COPYING for more details. */

    DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
    Version 2, December 2004

    Copyright (C) 2004 Sam Hocevar
    14 rue de Plaisance, 75014 Paris, France
    Everyone is permitted to copy and distribute verbatim or modified
    copies of this license document, and changing it is allowed as long
    as the name is changed.

    DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
    TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

    0. You just DO WHAT THE FUCK YOU WANT TO.

=cut

