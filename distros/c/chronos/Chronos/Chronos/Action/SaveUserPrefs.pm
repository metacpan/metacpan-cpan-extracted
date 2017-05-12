# $Id: SaveUserPrefs.pm,v 1.1.1.1 2002/08/19 20:38:05 nomis80 Exp $
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
package Chronos::Action::SaveUserPrefs;

use strict;
use Chronos::Action;

our @ISA = qw(Chronos::Action);

sub authorized {
    return 1;
}

sub header {
    return '';
}

sub content {
    my $self        = shift;
    my $chronos     = $self->{parent};
    my $dbh         = $chronos->dbh;
    my $user        = $chronos->user;
    my $user_quoted = $dbh->quote($user);

    my $lang       = $chronos->{r}->param('lang');
    my $agendatype = $chronos->{r}->param('agendatype');
    my ( $public_readable, $public_writable );
    if ( $agendatype eq 'publicrw' ) {
        $public_readable = 'Y';
        $public_writable = 'Y';
    } elsif ( $agendatype eq 'publicr' ) {
        $public_readable = 'Y';
        $public_writable = 'N';
    } else {
        $public_readable = 'N';
        $public_writable = 'N';
    }
    my $name  = $chronos->{r}->param('name');
    my $email = $chronos->{r}->param('email');
    $dbh->prepare(
"UPDATE user SET lang = ?, public_readable = ?, public_writable = ?, name = ?, email = ? WHERE user = ?"
      )
      ->execute( $lang, $public_readable, $public_writable, $name, $email,
        $user );

    if ( my $password = $chronos->{r}->param('password') ) {
        $dbh->prepare(
            "UPDATE user SET password = PASSWORD('$password') WHERE user = ?")
          ->execute($user);
    }

    my $sth = $dbh->prepare("SELECT user FROM user WHERE user != $user_quoted");
    my $sth_acl_select =
      $dbh->prepare(
        "SELECT user FROM acl WHERE object = $user_quoted AND user = ?");
    my $sth_acl_insert =
      $dbh->prepare(
        "INSERT INTO acl (object, user, can_read, can_write) VALUES(?, ?, ?, ?)"
      );
    my $sth_acl_update =
      $dbh->prepare(
"UPDATE acl SET can_read = ?, can_write = ? WHERE object = ? AND user = ?"
      );
    $sth->execute;
    while ( my $userr = $sth->fetchrow_array ) {
        my $priv = $chronos->{r}->param("indivpriv_$userr");
        my ( $can_read, $can_write );
        if ( $priv eq 'rw' ) {
            $can_read  = 'Y';
            $can_write = 'Y';
        } elsif ( $priv eq 'r' ) {
            $can_read  = 'Y';
            $can_write = 'N';
        } else {
            $can_read  = 'N';
            $can_write = 'N';
        }

        $sth_acl_select->execute($userr);
        if ( $sth_acl_select->fetchrow_array ) {
            $sth_acl_update->execute( $can_read, $can_write, $user, $userr );
        } else {
            $sth_acl_insert->execute( $user, $userr, $can_read, $can_write );
        }
        $sth_acl_select->finish;
    }
    $sth->finish;

    $chronos->{r}->header_out( "Location", $chronos->{r}->uri );
}

sub redirect {
    return 1;
}

1;

# vim: set et ts=4 sw=4 ft=perl:
