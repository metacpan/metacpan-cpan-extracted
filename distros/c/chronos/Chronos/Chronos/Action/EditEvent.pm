# $Id: EditEvent.pm,v 1.6 2002/08/28 19:15:29 nomis80 Exp $
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
package Chronos::Action::EditEvent;

use strict;
use Chronos::Action;
use Date::Calc qw(:all);
use Chronos::Static qw(from_datetime from_date from_time userstring);
use HTML::Entities;
use URI::Find::Schemeless;

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

    if ( my $eid = $chronos->{r}->param('eid') ) {
        return 1
          if $object eq $dbh->selectrow_array(
            "SELECT initiator FROM events WHERE eid = $eid");
        return 1
          if $dbh->selectrow_array(
"SELECT user FROM participants WHERE eid = $eid AND user = $object_quoted"
          );
        return 0;
    } else {
        return 1;
    }
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

    my ( $year, $month, $day, $hour ) = $chronos->dayhour;
    my $minimonth = $self->{parent}->minimonth( $year, $month, $day );
    my $form = $self->form( $year, $month, $day, $hour );

    return <<EOF;
<table width="100%" style="border:none">
    <tr>
        <td valign=top>$minimonth</td>
        <td width="100%">$form</td>
    </tr>
</table>
EOF
}

sub form {
    my $self    = shift;
    my $object  = $self->object;
    my $chronos = $self->{parent};
    my $uri     = $chronos->{r}->uri;
    my $text    = $chronos->gettext;
    my ( $year, $month, $day, $hour ) = @_;
    my $dbh = $chronos->dbh;

    my $eid = $chronos->{r}->param('eid');
    my %event;
    if ($eid) {
        %event =
          %{ $dbh->selectrow_hashref("SELECT * FROM events WHERE eid = $eid") };
    }
    @event{qw(syear smonth sday shour smin ssec)} =
      ( from_date( $event{start_date} ), from_time( $event{start_time} ) );
    @event{qw(eyear emonth eday ehour emin esec)} =
      ( from_date( $event{end_date} ), from_time( $event{end_time} ) );
    if ( $event{rid} ) {
        @event{qw(recurrent recur_until)} =
          $dbh->selectrow_array(
            "SELECT every, last FROM recur WHERE rid = $event{rid}");
        @event{qw(ryear rmonth rday)} = from_date( $event{recur_until} );
    }
    my $notime = ( $eid and not defined $event{start_time} ) ? 1 : 0;

    if ( $eid and $event{initiator} ne $self->object ) {
        # Modification d'un événement existant par un participant
        my $stext =
          encode_entities( Date_to_Text_Long( @event{qw(syear smonth sday)} )
              . ( $notime ? '' : sprintf( ' %d:%02d', @event{qw(shour smin)} ) )
          );
        my $etext =
          encode_entities( Date_to_Text_Long( @event{qw(eyear emonth eday)} )
              . ( $notime ? '' : sprintf( ' %d:%02d', @event{qw(ehour emin)} ) )
          );
        my $recur =
          $event{recurrent}
          ? $text->{ "eventrecur" . lc $event{recurrent} }
          : $text->{eventnotrecur};
        my $rtext =
          $event{recur_until}
          ? encode_entities(
            Date_to_Text_Long( @event{qw(ryear rmonth rday)} ) )
          : '-';

        my $initiator_quoted = $dbh->quote( $event{initiator} );
        my $participants     = userstring(
            $dbh->selectrow_array(
"SELECT user, name, email FROM user WHERE user = $initiator_quoted"
            )
          )
          . " <b>($text->{initiator})</b>";
        my $sth = $dbh->prepare( <<EOF );
SELECT user.user, user.name, user.email, participants.status
FROM user, participants
WHERE
    participants.eid = $eid
    AND participants.user = user.user
ORDER BY user.name, user.user
EOF
        $sth->execute;

        while ( my ( $user, $name, $email, $status ) = $sth->fetchrow_array ) {
            my $userstring = userstring( $user, $name, $email );
            my $statusstring =
              $status ? "<b>(" . $text->{"status_$status"} . ")</b>" : '';
            $participants .= "<br>$userstring $statusstring";
            if ( $user eq $self->object ) {
                if ( $status ne 'CANCELED' ) {
                    $participants .=
" <input type=submit name=cancel value=\"$text->{cancel}\">";
                }
                if ( $status ne 'CONFIRMED' ) {
                    $participants .=
" <input type=submit name=confirm value=\"$text->{confirm}\">";
                }
            }
        }
        $sth->finish;

        my $description = $event{description};
        $description =~ s/\n/<br>/g;

        # make all links in the description clickable
        my $finder = URI::Find::Schemeless->new(
            sub {
                my ( $uri, $orig_uri ) = @_;
                return qq|<a href="$uri" target=_blank>$orig_uri</a>|;
            }
        );
        $finder->find( \$description );
        # same thing for email addresses
        $description =~
          s/(\w[\w.-]+\@\w[\w.-]*\.[\w]+)/<a href="mailto:$1">$1<\/a>/g;

        my $return = <<EOF;
<form method=POST action="$uri" enctype="multipart/form-data" name="form1">
<input type=hidden name=action value=saveevent>
<input type=hidden name=object value="$object">
<input type=hidden name=year value=$year>
<input type=hidden name=month value=$month>
<input type=hidden name=day value=$day>
<input type=hidden name=eid value=$eid>

<table class=editevent>
    <tr>
        <td class=eventlabel>$text->{eventname}</td>
        <td>$event{name}</td>
    </tr>
    <tr>
        <td class=eventlabel>$text->{eventstart}</td>
        <td>$stext</td>
    </tr>
    <tr>
        <td class=eventlabel>$text->{eventend}</td>
        <td>$etext</td>
    </tr>
    <tr>
        <td class=eventlabel>$text->{eventdescription}</td>
        <td>$description</td>
    </tr>
    <tr>
        <td class=eventlabel><img src="/chronos_static/recur.png"> $text->{eventrecur}</td>
        <td>$recur</td>
    </tr>
    <tr>
        <td class=eventlabel>$text->{eventrecurend}</td>
        <td>$rtext</td>
    </tr>
    <tr>
        <td class=eventlabel>$text->{eventparticipants}</td>
        <td>$participants</td>
    </tr>
    <tr>
        <td class=eventlabel><img src="/chronos_static/bell.png"> $text->{reminder}</td>
EOF

        my ( %selunit, %selnumber );
        my $reminder_datetime;
        if ( $event{initiator} eq $self->object ) {
            $reminder_datetime = $event{reminder};
        } else {
            $reminder_datetime =
              $dbh->selectrow_array(
                "SELECT reminder FROM participants WHERE eid = $eid");
        }
        if ( defined $reminder_datetime ) {
            my ( $Dd, $Dh, $Dm ) = Delta_DHMS(
                from_datetime($reminder_datetime),
                from_date( $event{start_date} ),
                from_time( $event{start_time} )
            );
            if ( $Dd and not $Dh ) {
                $selunit{day} = 'selected';
                $selnumber{$Dd} = 'selected';
            } elsif ($Dh) {
                $selunit{hour} = 'selected';
                $selnumber{ $Dh + 24 * $Dd } = 'selected';
            } elsif ($Dm) {
                $selunit{min} = 'selected';
                $selnumber{$Dm} = 'selected';
            }
        }

        my $reminder_number = "<select name=reminder_number><option>-</option>";
        foreach ( 1, 2, 4, 8, 12, 24, 36, 48 ) {
            $reminder_number .= "<option $selnumber{$_}>$_</option>";
        }
        $reminder_number .= "</select>";
        my $reminder_unit = "<select name=reminder_unit>";
        foreach (qw(min hour day)) {
            $reminder_unit .=
              "<option value=$_ $selunit{$_}>$text->{$_}</option>";
        }
        $reminder_unit .= "</select>";
        my $remind_me = $text->{remind_me};
        $remind_me =~ s/\%1/$reminder_number/;
        $remind_me =~ s/\%2/$reminder_unit/;
        $return .= <<EOF;
        <td>$remind_me</td>
    </tr>
EOF
        $return .= <<EOF;
    <tr>
        <td class=eventlabel><img src="/chronos_static/file.png"> $text->{attachments}</td>
        <td>
EOF
        if (
            $dbh->selectrow_array(
                "SELECT COUNT(*) FROM attachments WHERE eid = $eid"
            )
          )
        {
            $return .= <<EOF;
            <table class=attachments>
EOF
            my $sth_files =
              $dbh->prepare(
"SELECT aid, filename, size FROM attachments WHERE eid = $eid ORDER BY filename"
              );
            $sth_files->execute;
            while ( my ( $aid, $filename, $size ) = $sth_files->fetchrow_array )
            {
                $filename = encode_entities($filename);
                $size     = format_size($size);
                $return .= <<EOF;
                <tr>
                    <td class=attachment>
                        <a href="$uri/getfile/$aid/$filename" class=attachment>$filename</a>
                    </td>
                    <td class=attachment>$size</td>
                    <td valign=top>
                        <a href="$uri?action=delfile&amp;aid=$aid&amp;eid=$eid&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day"><img src="/chronos_static/trash.png"></a>
                    </td>
                </tr>
EOF
            }
            $sth_files->finish;

            $return .= <<EOF;
            </table>
EOF
        }
        $return .= <<EOF;
        <img src="/chronos_static/filenew.png"> $text->{new_attachment} <input type=file name=new_attachment>
        </td>
    </tr>
    <tr>
        <td colspan=2>
            <input type=submit value="$text->{eventsave}">
EOF
        if ( $event{initiator} eq $self->object ) {
            $return .= <<EOF;
            &nbsp;<input type=submit name=delete value="$text->{eventdel}">
EOF
        }
        $return .= <<EOF;
        </td>
    </tr>
</table>

</form>
EOF
        return $return;

    } else {
        # Création d'un nouvel événement ou modification d'un événement
        # existant par l'initiateur
        my $return = <<EOF;
<form method=POST action="$uri" enctype="multipart/form-data" name="form1">
<input type=hidden name=action value=saveevent>
<input type=hidden name=object value="$object">
<input type=hidden name=year value=$year>
<input type=hidden name=month value=$month>
<input type=hidden name=day value=$day>
EOF
        if ($eid) {
            $return .= <<EOF;
<input type=hidden name=eid value=$eid>
EOF
        }
        $return .= <<EOF;

<table class=editevent>
    <tr>
        <td class=eventlabel>$text->{eventname}</td>
        <td><input name=name value="$event{name}" size=52></td>
    </tr>
    <tr>
        <td class=eventlabel>$text->{eventstart}</td>
        <td>
            <select name=start_month>
EOF
        foreach ( 1 .. 12 ) {
            my $month_name = Month_to_Text($_);
            my $selected = $_ == ( $event{smonth} || $month ) ? 'selected' : '';
            $return .= <<EOF;
                <option value=$_ $selected>$month_name</option>
EOF
        }
        $return .= <<EOF;
            </select>
            <select name=start_day>
EOF
        foreach ( 1 .. 31 ) {
            my $selected = $_ == ( $event{sday} || $day ) ? 'selected' : '';
            $return .= <<EOF;
                <option $selected>$_</option>
EOF
        }
        $return .= <<EOF;
            </select>
            <select name=start_year>
EOF
        foreach ( ( $year - 5 ) .. ( $year + 5 ) ) {
            my $selected = $_ == ( $event{syear} || $year ) ? 'selected' : '';
            $return .= <<EOF;
                <option $selected>$_</option>
EOF
        }
        $return .= <<EOF;
            </select>
            <select name=start_hour style="visibility:@{[$notime ? 'hidden' : 'visible']}">
EOF
        foreach ( '00' .. '23' ) {
            my $selected = $_ == ( $event{shour} || $hour ) ? 'selected' : '';
            my $value = int $_;
            $return .= <<EOF;
                <option value=$value $selected>$_</option>
EOF
        }
        $return .= <<EOF;
            </select>
            <select name=start_min style="visibility:@{[$notime ? 'hidden' : 'visible']}">
EOF
        foreach ( 0, 15, 30, 45 ) {
            my $string = sprintf ':%02d', $_;
            my $selected = $_ == $event{smin} ? 'selected' : '';
            $return .= <<EOF;
                <option value=$_ $selected>$string</option>
EOF
        }
        $return .= <<EOF;
            </select>
        </td>
    </tr>
    <tr>
        <td class=eventlabel>$text->{eventend}</td>
        <td>
            <select name=end_month>
EOF
        foreach ( 1 .. 12 ) {
            my $month_name = Month_to_Text($_);
            my $selected = $_ == ( $event{emonth} || $month ) ? 'selected' : '';
            $return .= <<EOF;
                <option value=$_ $selected>$month_name</option>
EOF
        }
        $return .= <<EOF;
            </select>
            <select name=end_day>
EOF
        foreach ( 1 .. 31 ) {
            my $selected = $_ == ( $event{eday} || $day ) ? 'selected' : '';
            $return .= <<EOF;
                <option $selected>$_</option>
EOF
        }
        $return .= <<EOF;
            </select>
            <select name=end_year>
EOF
        foreach ( ( $year - 5 ) .. ( $year + 5 ) ) {
            my $selected = $_ == ( $event{eyear} || $year ) ? 'selected' : '';
            $return .= <<EOF;
                <option $selected>$_</option>
EOF
        }
        $return .= <<EOF;
            </select>
            <select name=end_hour style="visibility:@{[$notime ? 'hidden' : 'visible']}">
EOF
        foreach ( '00' .. '23' ) {
            my $selected =
              $_ == ( $event{ehour} || $hour + 2 ) ? 'selected' : '';
            my $value = int $_;
            $return .= <<EOF;
                <option value=$value $selected>$_</option>
EOF
        }
        $return .= <<EOF;
            </select>
            <select name=end_min style="visibility:@{[$notime ? 'hidden' : 'visible']}">
EOF
        foreach ( 0, 15, 30, 45 ) {
            my $string = sprintf ':%02d', $_;
            my $selected = $_ == $event{emin} ? 'selected' : '';
            $return .= <<EOF;
                <option value=$_ $selected>$string</option>
EOF
        }

        $return .= <<EOF;
            </select>
            <br>
            <input type=checkbox name=notime onClick="
if (this.checked) {
    document.form1.start_hour.style.visibility = 'hidden';
    document.form1.start_min.style.visibility = 'hidden';
    document.form1.end_hour.style.visibility = 'hidden';
    document.form1.end_min.style.visibility = 'hidden';
} else {
    document.form1.start_hour.style.visibility = 'visible';
    document.form1.start_min.style.visibility = 'visible';
    document.form1.end_hour.style.visibility = 'visible';
    document.form1.end_min.style.visibility = 'visible';
}
            " @{[$notime ? 'checked' : '']}> $text->{notime}
        </td>
    </tr>
    <tr>
        <td class=eventlabel>$text->{eventdescription}</td>
        <td><textarea name=description cols=50 rows=8>$event{description}</textarea></td>
    </tr>
EOF
        unless ($eid) {
            $return .= <<EOF;
    <tr>
        <td class=eventlabel><img src="/chronos_static/recur.png"> $text->{eventrecur}</td>
        <td>
            <select name=recur>
                <option value="NULL">$text->{eventnotrecur}</option>
                <option value="DAY">$text->{eventrecurday}</option>
                <option value="WEEK">$text->{eventrecurweek}</option>
                <option value="MONTH">$text->{eventrecurmonth}</option>
                <option value="YEAR">$text->{eventrecuryear}</option>
            </select>
        </td>
    </tr>
    <tr>
        <td class=eventlabel>$text->{eventrecurend}</td>
        <td>
            <select name=recur_end_month>
EOF
            foreach ( 1 .. 12 ) {
                my $month_name = Month_to_Text($_);
                my $selected   =
                  $_ == ( $event{rmonth} || $month ) ? 'selected' : '';
                $return .= <<EOF;
                <option value=$_ $selected>$month_name</option>
EOF
            }
            $return .= <<EOF;
            </select>
            <select name=recur_end_day>
EOF
            foreach ( 1 .. 31 ) {
                my $selected = $_ == ( $event{rday} || $day ) ? 'selected' : '';
                $return .= <<EOF;
                <option $selected>$_</option>
EOF
            }
            $return .= <<EOF;
            </select>
            <select name=recur_end_year>
EOF
            foreach ( ( $year - 5 ) .. ( $year + 5 ) ) {
                my $selected =
                  $_ == ( $event{ryear} || $year ) ? 'selected' : '';
                $return .= <<EOF;
                <option $selected>$_</option>
EOF
            }
            $return .= <<EOF;
            </select>
        </td>
    </tr>
EOF
        } else {
            my $recur =
              $event{recurrent}
              ? $text->{ "eventrecur" . lc $event{recurrent} }
              : $text->{eventnotrecur};
            my $rtext =
              $event{recur_until}
              ? encode_entities(
                Date_to_Text_Long( @event{qw(ryear rmonth rday)} ) )
              : '-';
            $return .= <<EOF;
    <tr>
        <td class=eventlabel><img src="/chronos_static/recur.png"> $text->{eventrecur}</td>
        <td>$recur</td>
    </tr>
    <tr>
        <td class=eventlabel>$text->{eventrecurend}</td>
        <td>$rtext</td>
    </tr>
EOF
        }

        $return .= <<EOF;
    <tr>
        <td class=eventlabel>$text->{eventparticipants}</td>
        <td>
EOF

        if ($eid) {
            my ( $user, $name, $email ) =
              $dbh->selectrow_array(
"SELECT user.user, user.name, user.email FROM user, events WHERE events.eid = $eid AND events.initiator = user.user"
              );
            my $initiator = $self->{parent}->user eq $user ? 1 : 0;
            my $userstring = userstring( $user, $name, $email );
            $return .= <<EOF;
            $userstring <b>($text->{initiator})</b>
EOF

            my $sth =
              $dbh->prepare(
"SELECT user.user, user.name, user.email, participants.status FROM user, participants WHERE participants.eid = $eid AND participants.user = user.user ORDER BY user.name, user.user"
              );
            $sth->execute;
            my %participants;
            while ( my ( $user, $name, $email, $status ) =
                $sth->fetchrow_array )
            {
                $participants{$user} = 1;
                my $userstring = userstring( $user, $name, $email );
                my $statusstring =
                  $status ? "<b>(" . $text->{"status_$status"} . ")</b>" : '';
                $return .= <<EOF;
            <br>$userstring $statusstring
EOF
                if ( $user eq $self->object ) {
                    if ( $status ne 'CANCELED' ) {
                        $return .=
"<input type=submit name=cancel value=\"$text->{cancel}\">";
                    }
                    if ( $status ne 'CONFIRMED' ) {
                        $return .=
"<input type=submit name=confirm value=\"$text->{confirm}\">";
                    }
                }

                if ($initiator) {
                    $return .=
"<input type=submit name=\"remove_$user\" value=\"$text->{remove_part}\">";
                }
            }
            $sth->finish;

            $return .= <<EOF;
            </td>
        </tr>
        <tr>
            <td class=eventlabel>$text->{participants_to_add}</td>
            <td>
                <select size=5 multiple name=participants>
EOF
            $sth =
              $dbh->prepare(
"SELECT user, name, email FROM user WHERE user != ? AND user != ? ORDER BY name, user"
              );
            $sth->execute( $self->object, $user );
            while ( my ( $user, $name, $email ) = $sth->fetchrow_array ) {
                next if $participants{$user};
                my $string =
                  ( $name || $user ) . ( $email ? " &lt;$email&gt;" : '' );
                $return .= <<EOF;
                    <option value="$user">$string</option>
EOF
            }
            $sth->finish;
            $return .= <<EOF;
                </select><br>
                <img src="/chronos_static/email.png"> $text->{eventconfirm} <input type=checkbox name=confirm>
            </td>
        </tr>
EOF
        } else {
            $return .= <<EOF;
            <select size=5 multiple name=participants>
EOF
            my $sth =
              $dbh->prepare(
"SELECT user, name, email FROM user WHERE user != ? ORDER BY name, user"
              );
            $sth->execute( $self->object );
            while ( my ( $user, $name, $email ) = $sth->fetchrow_array ) {
                my $string =
                  ( $name || $user ) . ( $email ? " &lt;$email&gt;" : '' );
                $return .= <<EOF;
                <option value="$user">$string</option>
EOF
            }
            $sth->finish;
            $return .= <<EOF;
            </select>
EOF
        }

        $return .= <<EOF;
        </td>
    </tr>
EOF
        if ( not $eid ) {
            $return .= <<EOF;
    <tr>
        <td class=eventlabel><img src="/chronos_static/email.png"> $text->{eventconfirm}</td>
        <td><input type=checkbox name=confirm></td>
    </tr>
EOF
        }
        $return .= <<EOF;
    <tr>
        <td class=eventlabel><img src="/chronos_static/bell.png"> $text->{reminder}</td>
EOF

        my ( %selunit, %selnumber );
        if ($eid) {
            my $reminder_datetime;
            if ( $event{initiator} eq $self->object ) {
                $reminder_datetime = $event{reminder};
            } else {
                $reminder_datetime =
                  $dbh->selectrow_array(
                    "SELECT reminder FROM participants WHERE eid = $eid");
            }
            if ( defined $reminder_datetime ) {
                my @start_time = from_time( $event{start_time} );
                @start_time = ( 0, 0, 0 ) if not @start_time;
                my ( $Dd, $Dh, $Dm ) =
                  Delta_DHMS( from_datetime($reminder_datetime),
                    from_date( $event{start_date} ), @start_time );
                if ( $Dd and not $Dh ) {
                    $selunit{day} = 'selected';
                    $selnumber{$Dd} = 'selected';
                } elsif ($Dh) {
                    $selunit{hour} = 'selected';
                    $selnumber{ $Dh + 24 * $Dd } = 'selected';
                } elsif ($Dm) {
                    $selunit{min} = 'selected';
                    $selnumber{$Dm} = 'selected';
                }
            }
        }

        my $reminder_number = "<select name=reminder_number><option>-</option>";
        foreach ( 1, 2, 4, 8, 12, 24, 36, 48 ) {
            $reminder_number .= "<option $selnumber{$_}>$_</option>";
        }
        $reminder_number .= "</select>";
        my $reminder_unit = "<select name=reminder_unit>";
        foreach (qw(min hour day)) {
            $reminder_unit .=
              "<option value=$_ $selunit{$_}>$text->{$_}</option>";
        }
        $reminder_unit .= "</select>";
        my $remind_me = $text->{remind_me};
        $remind_me =~ s/\%1/$reminder_number/;
        $remind_me =~ s/\%2/$reminder_unit/;
        $return .= <<EOF;
        <td>$remind_me</td>
    </tr>
EOF
        $return .= <<EOF;
    <tr>
        <td class=eventlabel><img src="/chronos_static/file.png"> $text->{attachments}</td>
        <td>
EOF
        if (
            $eid
            and $dbh->selectrow_array(
                "SELECT COUNT(*) FROM attachments WHERE eid = $eid"
            )
          )
        {
            $return .= <<EOF;
            <table class=attachments>
EOF
            my $sth_files =
              $dbh->prepare(
"SELECT aid, filename, size FROM attachments WHERE eid = $eid ORDER BY filename"
              );
            $sth_files->execute;
            while ( my ( $aid, $filename, $size ) = $sth_files->fetchrow_array )
            {
                $filename = encode_entities($filename);
                $size     = format_size($size);
                $return .= <<EOF;
                <tr>
                    <td class=attachment>
                        <a href="$uri/getfile/$aid/$filename" class=attachment>$filename</a>
                    </td>
                    <td class=attachment>$size</td>
                    <td valign=top>
                        <a href="$uri?action=delfile&amp;aid=$aid&amp;eid=$eid&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day"><img src="/chronos_static/trash.png"></a>
                    </td>
                </tr>
EOF
            }
            $sth_files->finish;

            $return .= <<EOF;
            </table>
EOF
        }
        $return .= <<EOF;
            <img src="/chronos_static/filenew.png"> $text->{new_attachment} <input type=file name=new_attachment>
        </td>
    </tr>
EOF

        $return .= <<EOF;
    <tr>
        <td colspan=2>
            <input type=submit value="$text->{eventsave}">
EOF
        if ( $eid and $event{initiator} eq $self->object ) {
            $return .= <<EOF;
            &nbsp;<input type=submit name=delete value="$text->{eventdel}">
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
}

sub format_size {
    my $size = shift;
    if ( $size >= 1024 * 1024 * 1024 ) {
        return sprintf '%0.1f GB', $size / ( 1024 * 1024 * 1024 );
    } elsif ( $size >= 1024 * 1024 ) {
        return sprintf '%0.1f MB', $size / ( 1024 * 1024 );
    } elsif ( $size >= 1024 ) {
        return sprintf '%0.1f kB', $size / 1024;
    } else {
        return "$size B";
    }
}

1;

# vim: set et ts=4 sw=4 ft=perl:
