package VFSsimple::Drv::Rsync;

use strict;
use warnings;
use base qw(VFSsimple::Base);
use URI ();
use File::Temp qw(tempfile);

our $VERSION = '0.03';

=head1 NAME

VFSsimple::Drv::Rsync - A VFSsimple implementation over rsync protocol

=head1 DESCRIPTION

This module provide access method for VFSsimple module to access to file
located on rsync server.

=cut


sub drv_new {
    my ($self) = @_;
    foreach (split(':', $ENV{PATH})) {
        -x "$_/rsync" and return $self;
    }
    return;
}


sub drv_get {
    my ($self, $src) = @_;
    my (undef, $dest) = tempfile(UNLINK => 0);
    $self->drv_copy($src, $dest);
}

sub drv_copy {
    my ($self, $src, $dest) = @_;
    system('rsync', '-q', $self->{root} . '/' . $src, $dest);
    my $res = $? >> 8;
    if ($res) { return }
    return $dest;
}

sub drv_exists {
    my ($self, $file) = @_;
    system('rsync', '-q', "$self->{root}/$file");
    my $res = $? >> 8;
    return ($res eq 0);
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
