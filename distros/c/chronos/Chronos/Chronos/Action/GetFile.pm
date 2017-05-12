# $Id: GetFile.pm,v 1.1.1.1 2002/08/19 20:38:05 nomis80 Exp $
#
# Copyright (C) 2002  Linux Québec Technologies
#
# This file is part of Chronos.
#
# Chronos is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Chronos is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Foobar; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
package Chronos::Action::GetFile;

use strict;
use Chronos::Action;
use Apache::Constants qw(:response);

our @ISA = qw(Chronos::Action);

sub type {
    return 'read';
}

sub authorized {
    my $self          = shift;
    my $chronos       = $self->{parent};
    my $dbh           = $chronos->dbh;
    my $object        = $self->object;
    my $object_quoted = $dbh->quote($object);

    if ( $self->SUPER::authorized == 0 ) {
        return 0;
    }

    if ( my $aid = $self->aid ) {
        my $eid =
          $dbh->selectrow_array("SELECT eid FROM attachments WHERE aid = $aid");
        return 1
          if $object eq $dbh->selectrow_array(
            "SELECT initiator FROM events WHERE eid = $eid");
        return 1
          if $dbh->selectrow_array(
"SELECT user FROM participants WHERE eid = $eid AND user = $object_quoted"
          );
        return 0;
    } else {
        return 0;
    }
}

sub freeform {
    return 1;
}

sub execute {
    my $self    = shift;
    my $chronos = $self->{parent};
    my $dbh     = $chronos->dbh;

    my $aid = $self->aid;
    my ( $filename, $file ) =
      $dbh->selectrow_array(
        "SELECT filename, file FROM attachments WHERE aid = $aid");
    $chronos->{r}->content_type( getmime($filename) );
    $chronos->{r}->send_http_header;
    $chronos->{r}->print($file);

    return OK;
}

sub aid {
    my $self = shift;
    my $r    = $self->{parent}{r};
    my @path = split '/', $r->path_info;
    return $path[2];
}

sub getmime {
    my $filename = shift;
    ( my $extension = $filename ) =~ s/.*\.//;
    return 'application/octet-stream' if not $extension;
    if ( not %Chronos::Action::GetFile::types ) {
        # Cache parsing /etc/mime.types thanks to mod_perl
        open MIME, "/etc/mime.types";
        while (<MIME>) {
            next if /^#/ or /^\s*$/;
            my ( $type, @extensions ) = split;
            next if not @extensions;
            $Chronos::Action::GetFile::types{$_} = $type foreach @extensions;
        }
        close MIME;
    }
    return $Chronos::Action::GetFile::types{$extension}
      || 'application/octet-stream';
}

1;

# vim: set et ts=4 sw=4 ft=perl:
