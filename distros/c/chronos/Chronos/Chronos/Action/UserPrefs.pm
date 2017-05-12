# $Id: UserPrefs.pm,v 1.2 2002/08/28 19:15:29 nomis80 Exp $
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
package Chronos::Action::UserPrefs;

use strict;
use Chronos::Action;
use Chronos::Static qw(userstring);
use HTML::Entities;

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
    my $text        = $chronos->gettext;
    my $dbh         = $chronos->dbh;
    my $user        = $chronos->user;
    my $user_quoted = $dbh->quote($user);
    my $uri         = $chronos->{r}->uri;

    my $minimonth = $chronos->minimonth( $chronos->day );

    my ( $lang, $public_writable, $public_readable, $name, $email ) =
      $dbh->selectrow_array(
"SELECT lang, public_writable, public_readable, name, email FROM user WHERE user = $user_quoted"
      );
    $name  = encode_entities($name);
    $email = encode_entities($email);

    my $return = <<EOF;
<table style="border:none">
    <tr>
        <td valign=top>$minimonth</td>
        <td valign=top width="100%">

<form method=post action="$uri">
<input type=hidden name=action value=saveuserprefs>

<table class=editevent>
    <tr><th colspan=2>$text->{userprefs}</th></tr>
    <tr>
        <td><img src="/chronos_static/name.png"> $text->{name}</td>
        <td><input name=name value="$name"></td>
    </tr>
    <tr>
        <td><img src="/chronos_static/email.png"> $text->{email}</td>
        <td><input name=email value="$email"></td>
    </tr>
    <tr>
        <td><img src="/chronos_static/password.png"> $text->{password}</td>
        <td><input type=password name=password></td>
    </tr>
    <tr>
        <td><img src="/chronos_static/lang.png"> $text->{lang}</td>
        <td><select name=lang>
EOF

    my @langs = grep { -f } </usr/share/chronos/lang/*>;
    s|/usr/share/chronos/lang/|| foreach @langs;
    my %langs = map { $_ => $text->{$_} } @langs;
    foreach ( sort { $langs{$a} cmp $langs{$b} } keys %langs ) {
        my $selected = $_ eq $lang ? 'selected' : '';
        $return .= <<EOF;
            <option value="$_" $selected>$langs{$_}</option>
EOF
    }

    $return .= <<EOF;
        </select></td>
    </tr>
    <tr>
        <td>$text->{agendatype}</td>
        <td><select name=agendatype>
EOF

    my %agendatype;
    if ( $public_writable eq 'Y' and $public_readable eq 'Y' ) {
        $agendatype{publicrw} = 'selected';
    } elsif ( $public_readable eq 'Y' ) {
        $agendatype{publicr} = 'selected';
    } else {
        $agendatype{private} = 'selected';
    }
    $return .= <<EOF;
            <option value="publicrw" $agendatype{publicrw}>$text->{publicrw}</option>
            <option value="publicr" $agendatype{publicr}>$text->{publicr}</option>
            <option value="private" $agendatype{private}>$text->{private}</option>
        </select></td>
    </tr>
    <tr>
        <td valign=top>$text->{indivpriv}</td>
        <td>
            <table style="border:none; background-color:white">
EOF

    my $sth_user =
      $dbh->prepare(
"SELECT user, name, email FROM user WHERE user != $user_quoted ORDER BY name, user"
      );
    my $sth_acl =
      $dbh->prepare(
        "SELECT can_read, can_write FROM acl WHERE object= ? AND user = ?");

    $sth_user->execute;
    while ( my ( $userr, $name, $email ) = $sth_user->fetchrow_array ) {
        my $string = userstring( $userr, $name, $email );

        my %indivpriv;
        $sth_acl->execute( $user, $userr );
        my ( $can_read, $can_write ) = $sth_acl->fetchrow_array;
        $sth_acl->finish;

        if ( $can_read eq 'Y' and $can_write eq 'Y' ) {
            $indivpriv{rw} = 'selected';
        } elsif ( $can_read eq 'Y' ) {
            $indivpriv{r} = 'selected';
        } else {
            $indivpriv{none} = 'selected';
        }

        $return .= <<EOF;
                <tr>
                    <td>$string</td>
                    <td align=center>
                        <select name="indivpriv_$userr">
                            <option value=rw $indivpriv{rw}>$text->{rw}</option>
                            <option value=r $indivpriv{r}>$text->{r}</option>
                            <option value=none $indivpriv{none}>$text->{nopriv}</option>
                        </select>
                    </td>
                </tr>
EOF
    }
    $sth_user->finish;

    $return .= <<EOF;
            </table>
        </td>
    </tr>
    <tr>
        <td colspan=2>
            <input type=submit value="$text->{eventsave}">
        </td>
    </tr>
</table>

</form>

        </td>
    </tr>
</table>
EOF

    return $return;
}

1;

# vim: set et ts=4 sw=4 ft=perl:
