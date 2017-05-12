# $Id: EditTask.pm,v 1.2 2002/08/28 15:58:46 nomis80 Exp $
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
package Chronos::Action::EditTask;

use strict;
use Chronos::Action;
use Date::Calc qw(:all);

our @ISA = qw(Chronos::Action);

sub type {
    return 'read';
}

sub header {
    my $self   = shift;
    my $object = $self->object;
    my ( $year, $month, $day ) = $self->{parent}->day;
    my $text = $self->{parent}->gettext;
    my $uri  = $self->{parent}{r}->uri;
    return <<EOF;
<table style="margin-style:none" cellspacing=0 cellpadding=0 width="100%">
    <tr>
        <td class=header>@{[Date_to_Text_Long(Today())]}</td>
        <td class=header align=right>
            <a href="$uri?action=showmonth&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day"><img src="/chronos_static/showmonth.png" border=0>$text->{month}</a> |
            <a href="$uri?action=showweek&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day"><img src="/chronos_static/showweek.png" border=0>$text->{week}</a> |
            <a href="$uri?action=showday&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day"><img src="/chronos_static/showday.png" border=0>$text->{Day}</a>
        </td>
    </tr>
</table>
EOF
}

sub content {
    my $self    = shift;
    my $chronos = $self->{parent};

    my ( $year, $month, $day ) = $chronos->day;
    my $minimonth = $chronos->minimonth( $year, $month, $day );
    my $form      = $self->form( $year,         $month, $day );

    return <<EOF;
<table width="100%" style="border:none">
    <tr>
        <td valign=top>$minimonth</td>
        <td width="100%" valign=top>$form</td>
    </tr>
</table>
EOF
}

sub form {
    my $self   = shift;
    my $object = $self->object;
    my ( $year, $month, $day ) = @_;
    my $chronos = $self->{parent};
    my $dbh     = $chronos->dbh;
    my $text    = $chronos->gettext;
    my $uri     = $chronos->{r}->uri;

    my $tid = $chronos->{r}->param('tid');
    my ( $title, $notes, $priority );
    if ($tid) {
        ( $title, $notes, $priority ) =
          $dbh->selectrow_array(
            "SELECT title, notes, priority FROM tasks WHERE tid = $tid");
    }

    my $return = <<EOF;
<form method=POST action="$uri">
<input type=hidden name=action value=savetask>
<input type=hidden name=tid value="$tid">
<input type=hidden name=object value="$object">
<input type=hidden name=year value=$year>
<input type=hidden name=month value=$month>
<input type=hidden name=day value=$day>

<table class=editevent>
    <tr>
        <td class=eventlabel>$text->{tasktitle}</td>
        <td><input name=title value="$title"></td>
    </tr>
    <tr>
        <td class=eventlabel>$text->{tasknotes}</td>
        <td><textarea cols=80 rows=25 name=notes>$notes</textarea></td>
    </tr>
    <tr>
        <td class=eventlabel>$text->{taskpriority}</td>
        <td>
            <select name=priority>
EOF
    $priority ||= 5;
    foreach ( 1 .. 9 ) {
        my $selected = $_ eq $priority ? 'selected' : '';
        $return .= <<EOF;
            <option $selected>$_</option>
EOF
    }
    $return .= <<EOF;
            </select>
        </td>
    </tr>
    <tr>
        <td colspan=2>
            <input type=submit name=save value="$text->{eventsave}">
EOF
    if ($tid) {
        $return .= <<EOF;
            <input type=submit name=delete value="$text->{eventdel}">
EOF
    }
    $return .= <<EOF;
        </td>
    </tr>
</table>

</form>
EOF
    return $return;
}

1;

# vim: set et ts=4 sw=4 ft=perl:
