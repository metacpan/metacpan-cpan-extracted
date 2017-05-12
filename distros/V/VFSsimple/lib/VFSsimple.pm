package VFSsimple;

use strict;
use warnings;
use URI;

our $VERSION = '0.03';

=head1 NAME

VFSsimple

=head1 DESCRIPTION

A library to magically access to file w/o carry the method

=head1 SYNOPSIS

    my $vfs = VFSsimple->new($url)
        or die "can't get the vfs";

    $vfs->copy("path/fichier", "/tmp/fichier")
        or die "can't get file";

=head1 FUNCTIONS

=head2 new($root, $options)

Instanciate a new VFSimple object over $root url.

$root The root of the vfs

$options is a hashref:

=over 4

=item vfs

Force the virtal access method to use

=back

=head3 url parsing

The $root should be a valid url:

    protocol://server/path
    file://path

A standard file path can also be used, understood as file://.

The access method to use is find automatically using url infromation:

- protocol from url
- if protocol is either file:// or ext:// and target is a file, the extension
  is use.

The automatic behavior can overide by setting vfs option.

For local file abstraction, an additionnal path can be append to set the root
inside the archive:

    file://path/file.ext/subpath

=cut

sub new {
    my ($class, $root, $options) = @_;
    my $uri = URI->new($root) or return;
    $options->{uri} = $uri;
    my $fsclass = $options->{vfs};
    if (!$uri->scheme() || $uri->scheme() eq 'ext' || !$uri->authority) {
        my @part = split(/\/+/, $uri->path());
        my $path = (shift(@part) || '');
        while(!($path && -f $path) && @part) {
            $path .= '/' . shift(@part);
        }
        if (!$fsclass) {
            if (($uri->scheme() || '') eq 'ext' || (!$uri->scheme() && !$uri->authority)) {
                $path =~ m/\.([^\.]*)$/;
                $fsclass = $1 if ($1);
            }
        }
        if (@part) {
            $options->{rootfile} = $path;
            $options->{subpath} = '/' . join('/', @part);
        }
    } elsif(!$fsclass) {
        $fsclass = $uri->scheme();
    }
    $fsclass = ucfirst(lc($fsclass || 'file'));
    my $fullclass = "VFSsimple::Drv::$fsclass";
    eval "use $fullclass";
    # TODO the use can failed if package is load inline see t/02-instanciate.t
    # if ($@) {
    #   warn "Can't load $fullclass\n";
    #   return;
    # }
    no strict 'refs';
    return $fullclass->new($root, $options);
}

=head2 root

Return the root of the VFS.

=head2 error

Return the last error.

=cut

sub error {
    $_[0]->{_error}
}

=head2 get($src)

Fetch the file if necessary, and return the local location
where it has been copied.

=cut

sub get {
    my ($self, $src) = @_;
    return $self->drv_get($src);
}

=head2 open($src)

Fetch the file if necessary and return an open file handle
on it.

=cut

sub open {
    my ($self, $src) = @_;
    return $self->drv_open($src);
}

=head2 copy($src, $dest)

Copy $src file from vfs into $dest local file

=cut

sub copy {
    my ($self, $src, $dest) = @_;
    return $self->drv_copy($src, $dest);
}

=head2 exists($file)

Return True if $file exists on the VFS

=cut

sub exists {
    my ($self, $file) = @_;
    return $self->drv_exists($file);
}

1;

__END__

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
