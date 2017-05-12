# $Id: SaveTask.pm,v 1.1.1.1 2002/08/19 20:38:05 nomis80 Exp $
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
package Chronos::Action::SaveTask;

use strict;
use Chronos::Action;

our @ISA = qw(Chronos::Action);

sub type {
    return 'write';
}

sub header {
    return '';
}

sub content {
    my $self    = shift;
    my $object  = $self->object;
    my $chronos = $self->{parent};
    my $dbh     = $chronos->dbh;

    my $tid      = $chronos->{r}->param('tid');
    my $title    = $chronos->{r}->param('title');
    my $notes    = $chronos->{r}->param('notes');
    my $priority = $chronos->{r}->param('priority');

    $self->Chronos::Action::SaveEvent::error('notitle') if not $title;

    if ($tid) {
        if ( $chronos->{r}->param('delete') ) {
            # Suppression d'une tâche existante
            $dbh->do("DELETE FROM tasks WHERE tid = $tid");
        } else {
            # Modification d'une tâche existante
            $dbh->prepare(
"UPDATE tasks SET title = ?, notes = ?, priority = ? WHERE tid = ?"
            )->execute( $title, $notes, $priority, $tid );
        }
    } else {
        # Création d'une nouvelle tâche
        $dbh->prepare(
"INSERT INTO tasks (title, notes, priority, user) VALUES(?, ?, ?, ?)"
        )->execute( $title, $notes, $priority, $self->object );
    }

    my ( $year, $month, $day ) = $chronos->day;
    my $uri = $chronos->{r}->uri;
    $chronos->{r}->header_out( "Location",
        "$uri?action=showday&object=$object&year=$year&month=$month&day=$day" );
}

sub redirect {
    return 1;
}

1;

# vim: set et ts=4 sw=4 ft=perl:
