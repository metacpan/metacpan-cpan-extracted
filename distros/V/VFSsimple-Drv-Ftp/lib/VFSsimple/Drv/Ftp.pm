package VFSsimple::Drv::Ftp;

use strict;
use warnings;
use base qw(VFSsimple::Base);
use Net::FTP ();
use URI ();
use File::Temp qw(tempfile);

our $VERSION = '0.03';

=head1 NAME

VFSsimple::Drv::Ftp - A VFSsimple implementation over ftp protocol

=head1 DESCRIPTION

This module provide access method for VFSsimple module to access to file on
ftp server.

Access is provided using L<Net::FTP> module.

=cut

sub drv_new {
    my ($self) = @_;
    my $uri = URI->new($self->{root});
    my $ftp = Net::FTP->new($uri->host()) or return;
    my ($user, $pass) = ($uri->userinfo || '') =~ m/^([^:]):?(.*)?/;
    if (!$user) {
        $user = 'ftp';
        $pass = 'vfssimple@';
    }
    $ftp->login($user, $pass) or return;
    $ftp->pasv();
    
    $self->{uri} = $uri;
    $self->{ftp} = $ftp;
    return $ftp ? $self : ();
}

sub drv_copy {
    my ($self, $src, $dest) = @_;
    my ($dir, $file) = ($self->{uri}->path() . '/' . $src) =~ m:(.*)/+([^/]*):;
    $self->{ftp}->cwd($dir) or do {
        $self->set_error($self->{ftp}->message);
        return;
    };
    open(my $fh, '>', $dest) or return;
    $self->{ftp}->get($file, $fh) or do {
        $self->set_error($self->{ftp}->message);
        return;
    };
    close($fh);
    return $dest;
}

sub drv_exists {
    my ($self, $file) = @_;
    my ($dir, $filename) = ($self->{uri}->path() . '/' . $file) =~ m:(.*)/+([^/]*):;
    $self->{ftp}->cwd($dir) or do {
        $self->set_error($self->{ftp}->message);
        return;
    };
    return(defined($self->{ftp}->mdtm($filename)));
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
