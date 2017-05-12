# $Id: DelFile.pm,v 1.1.1.1 2002/08/19 20:38:04 nomis80 Exp $
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
package Chronos::Action::DelFile;

use strict;
use Chronos::Action;

our @ISA = qw(Chronos::Action);

sub type {
    return 'write';
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

    if ( my $aid = $chronos->{r}->param('aid') ) {
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

sub redirect {
    return 1;
}

sub content {
    my $self    = shift;
    my $object  = $self->object;
    my $chronos = $self->{parent};
    my $aid     = $chronos->{r}->param('aid');
    my $dbh     = $chronos->dbh;
    $dbh->do("DELETE FROM attachments WHERE aid = $aid");
    my $eid   = $chronos->{r}->param('eid');
    my $year  = $chronos->{r}->param('year');
    my $month = $chronos->{r}->param('month');
    my $day   = $chronos->{r}->param('day');
    my $uri   = $chronos->{r}->uri;
    $chronos->{r}->header_out( "Location",
"$uri?action=editevent&object=$object&eid=$eid&year=$year&month=$month&day=$day"
    );
}

1;

# vim: set et ts=4 sw=4 ft=perl:
