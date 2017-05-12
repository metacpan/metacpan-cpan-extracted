package VFSsimple::Base;

use strict;
use warnings;
use File::Temp qw(tempfile);
use IO::File;
use base qw(VFSsimple);

=head1 NAME

VFSsimple::Base

=head1 DESCRIPTION

A based module for any VFSimple driver.

=head1 SYNOPSIS

    package VFSsimple::Drv::Any;

    use base qw(VFSsimple::Base);
    use File::Copy;

    our $VERSION = '0.01';

    sub drv_new {
        my ($self) = @_;
        ...
        return $self;
    }

    sub drv_get {
        my ($self, $src) = @_;
        return $self->{realroot} . '/' . $src;
    }

    sub drv_copy {
        my ($self, $src, $dest) = @_;
        return File::Copy::copy($self->{realroot} . '/' . $src, $dest) ? $dest : ();
    }

    1;

=cut

sub new {
    my ($class, $root, $options) = @_;
    my $fs = {
        root => $root,
        options => $options,
    };
    bless($fs, $class);
    return $fs->drv_new();
}

=head1 PROVIDED FUNCTIONS

=head2 set_error($fmt, ...)

Store last error message 

=cut

sub set_error {
    my ($self, $fmt, @args) = @_;
    $self->{_error} = sprintf($fmt, @args);
}

=head2 root

Return the root url of the VFS

=cut

sub root {
    my ($self) = @_;
    return $self->{root};
}

=head2 archive_path

If VFS handle a tree inside an archive, return the path of this archive.

=cut

sub archive_path {
    my ($self) = @_;
    return $self->{options}{rootfile}
}

=head2 archive_path

If VFS handle a tree inside an archive, return the virtual root path inside
the archive.

=cut

sub archive_subpath {
    my ($self) = @_;
    return $self->{options}{subpath}
}

=head1 FUNCTIONS PROVIDED BY DRIVER

=head2 drv_new

This function is called during object creation (new). It receive as arguments
the fresh blessed object and allow the driver to load data it will need to
work.

Should return the object in case of success, nothing on error.

=cut

sub drv_new {
    my ($self) = @_;
    return $self;
}

=head2 drv_copy($source, $dest)

This function should copy $source relative path from vfs to $dest local path.

Should return True on success.

=cut

sub drv_copy {
    my ($self, $src, $dest) = @_;
    $self->set_error("no drv_copy support");
    return;
}

=head2 drv_get($src)

Should return any file path where the file can be locally found, nothing on
error.

If this function is not provided, a default from L<VFSimple::Base> is provided
generating a temporary file and using drv_copy() to fetch it.

=cut

sub drv_get {
    my ($self, $src) = @_;
    my (undef, $dest) = File::Temp::tempfile(UNLINK => 0);
    return $self->drv_copy($src, $dest);
}

=head2 drv_open($src)

Should return a B<read only> file handle for relative path $src.

If the function is not provide, default return an open file handle over a
deleted temp file using drv_copy to fetch the file.

=cut

sub drv_open {
    my ($self, $src) = @_;
    my $dest = $self->drv_get($src) or return;
    CORE::open(my $tmpfile, '<', $dest) or return;
    return $tmpfile;
}

=head2 drv_exists($file)

Should true if $file exists

=cut

sub drv_exists {
    my ($self, $file) = @_;
    $self->set_error("no drv_exists support");
    return;
}

1;

__END__

=head1 SEE ALSO

L<VFSimple>

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

