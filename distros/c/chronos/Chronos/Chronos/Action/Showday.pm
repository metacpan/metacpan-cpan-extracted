# $Id: Showday.pm,v 1.12 2002/09/16 23:20:31 nomis80 Exp $
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
package Chronos::Action::Showday;

use strict;
use Chronos::Action;
use Date::Calc qw(:all);
use Chronos::Static qw(from_date from_time to_date to_time Compare_YMD);
use HTML::Entities;
use Chronos::Action::Showmonth;
use URI::Find::Schemeless;

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
    my $date =
      $self->{parent}->format_date( $self->{parent}->conf->{HEADER_DATE_FORMAT},
        Today_and_Now() );
    return <<EOF;
<table style="margin-style:none" cellspacing=0 cellpadding=0 width="100%">
    <tr>
        <td class=header>$date</td>
        <td class=header align=right valign=bottom>
            <a href="$uri?action=showmonth&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day"><img src="/chronos_static/showmonth.png" border=0>$text->{month}</a> |
            <a href="$uri?action=showweek&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day"><img src="/chronos_static/showweek.png" border=0>$text->{week}</a>
        </td>
    </tr>
</table>
EOF
}

sub content {
    my $self    = shift;
    my $chronos = $self->{parent};
    my $text    = $chronos->gettext;

    my ( $year, $month, $day ) = $chronos->day;
    my $minimonth = $self->{parent}->minimonth( $year, $month, $day );
    my $dayview  = $self->dayview( $year,  $month, $day );
    my $taskview = $self->taskview( $year, $month, $day );

    return <<EOF;
<table width="100%" style="border:none">
    <tr>
        <td valign=top>
$minimonth
            <br>
$taskview
        </td>
        <td width="100%">
$dayview
        </td>
    </tr>
</table>
EOF
}

sub taskview {
    my $self   = shift;
    my $object = $self->object;
    my ( $year, $month, $day ) = @_;
    my $chronos = $self->{parent};
    my $dbh     = $chronos->dbh;
    my $text    = $chronos->gettext;
    my $uri     = $chronos->{r}->uri;

    my $return = <<EOF;
<!-- Begin Chronos::Action::Showday::tasksview -->
<table class=taskview width="100%">
    <tr><th class=minimonth>$text->{tasklist}</th></tr>
    <tr><td>
EOF

    my $sth =
      $dbh->prepare(
"SELECT tid, title, priority FROM tasks WHERE user = ? ORDER BY priority, title"
      );
    $sth->execute( $self->object );
    while ( my ( $tid, $title, $priority ) = $sth->fetchrow_array ) {
        $title = encode_entities($title);
        $return .=
qq(&bull; <img src="/chronos_static/priority$priority.png"> <a href="$uri?action=edittask&amp;tid=$tid&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day">$title</a><br>);
    }
    $sth->finish;
    $return .= qq(</ul></td></tr>\n) . <<EOF;
    <tr>
        <td class=minimonthfooter><a href="$uri?action=edittask&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day">$text->{newtask}</a></td>
    </tr>
</table>
<!-- End Chronos::Action::Showday::taskview -->
EOF
    return $return;
}

sub dayview {
    my $self    = shift;
    my $object  = $self->object;
    my $chronos = $self->{parent};
    my $conf    = $chronos->conf;
    my ( $year, $month, $day ) = @_;

    my $dbh  = $chronos->dbh;
    my $text = $chronos->gettext;
    my $uri  = $chronos->{r}->uri;

    my $return = <<EOF;
<!-- Begin Chronos::Action::Showday::dayview -->
<table class=dayview cellpadding=0 cellspacing=0 width="100%" style="border-top:none; border-left:none">
    <tr>
EOF

    my $user_quoted = $dbh->quote( $self->object );

    # These statements are my pride and my joy

    # Find how many events are happening concurrently +- 1 hour (ie. will occupy
    # the same row when displayed in a grid having 1 row for each hour). This
    # statement find the events the user himself started.
    my $sth_simul_events = $dbh->prepare( <<EOF );
SELECT COUNT(*) 
FROM events 
WHERE
    initiator = $user_quoted 
    AND (
            start_date < ?
        OR
            start_date = ?
            AND (
                    start_time <= ?
                OR
                    start_time IS NULL
            )
    )
    AND (
            end_date > ?
        OR
            end_date = ?
            AND (
                    end_time > ?
                OR
                    end_time = ?
                    AND end_date = start_date
                    AND end_time = start_time
                OR
                    end_time IS NULL
            )
    )
EOF
    # This statement finds the events the user is participant of.
    my $sth_simul_participants = $dbh->prepare( <<EOF );
SELECT COUNT(*)
FROM events, participants
WHERE
    events.eid = participants.eid
    AND participants.user = $user_quoted
    AND (
            events.start_date < ?
        OR
            events.start_date = ?
            AND (
                    events.start_time < ?
                OR
                    events.start_time IS NULL
            )
    )
    AND (
            events.end_date > ?
        OR
            events.end_date = ?
            AND (
                    events.end_time > ?
                OR
                    events.end_time = ?
                    AND events.end_date = events.start_date
                    AND events.end_time = events.start_time
                OR
                    events.end_time IS NULL
            )
    )
EOF

    # The two statements defined above take these parameters:
    # 1) The date of the current day
    # 2) The date of the current day
    # 3) The current hour + 59:59
    # 4) The date of the current day
    # 5) The date of the current day
    # 6) The current hour
    # 7) The current hour

    my $today_date = to_date( $year, $month, $day );

    my $max_simul_events;
    foreach my $hour ( 0 .. 23 ) {
        my $curhour_time  = to_time($hour);
        my $nexthour_time = to_time( $hour, 59, 59 );

        $sth_simul_events->execute(
            $today_date, $today_date,   $nexthour_time, $today_date,
            $today_date, $curhour_time, $curhour_time
        );
        $sth_simul_participants->execute(
            $today_date, $today_date,   $nexthour_time, $today_date,
            $today_date, $curhour_time, $curhour_time
        );
        my $simul_events = $sth_simul_events->fetchrow_array +
          $sth_simul_participants->fetchrow_array;
        $sth_simul_events->finish;
        $sth_simul_participants->finish;
        $max_simul_events = $simul_events if $simul_events > $max_simul_events;
    }

    my $daystring = $chronos->format_date( $conf->{DAYVIEW_DATE_FORMAT},
        $year, $month, $day, 0, 0, 0 );
    my $holidays =
      Chronos::Action::Showmonth::get_holidays( $self, $year, $month, $day );
    $return .= <<EOF;
        <th style="border-top:hidden; border-left:hidden;"></th>
        <th class=dayview colspan=@{[($max_simul_events || 1) + 0]}>$daystring@{[$year == 1983 && $month == 2 && $day == 3 ? " (Simon Perreault's birth day!)" : '']}$holidays</th>
    </tr>
EOF

    my ( $to_year, $to_month, $to_day, $to_hour ) = Today_and_Now();
    if ( $max_simul_events == 0 ) {
        # Go fast, don't check DB at each hour. We know anyway that there are no
        # events today.
        foreach my $hour ( 0 .. 23 ) {
            my $class;
            if (    $year == $to_year
                and $month == $to_month
                and $day == $to_day
                and $hour == $to_hour )
            {
                $class = 'dayviewcurhour';
            } else {
                $class = 'dayviewhour';
            }
            $return .= <<EOF;
    <tr>
        <td class=$class><a href="$uri?action=editevent&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day&amp;hour=$hour">$hour:00</a></td>
        <td class=dayview>&nbsp;</td>
    </tr>
EOF
        }
    } else {

        # Find the events happening for the first hour of the day
        # (that's midnight to one). This hour is different from the others
        # because events started before the current day have to be displayed.
        # Other hours only display the events starting then, thanks to HTML's
        # rowspan.
        my $sth_events_first_hour = $dbh->prepare( <<EOF );
SELECT eid, name, start_date, start_time, end_date, end_time, description, reminder, rid
FROM events
WHERE
    initiator = $user_quoted
    AND end_date >= ?
    AND (
            start_date < ?
        OR
            start_date = ?
            AND (
                    start_time < '01:00:00'
                OR
                    start_time IS NULL
            )
    )
ORDER BY start_date, start_time
EOF
        my $sth_participants_first_hour = $dbh->prepare( <<EOF );
SELECT events.eid, events.name, events.start_date, events.start_time, events.end_date, events.end_time, events.description, participants.reminder, events.rid, participants.status
FROM events, participants
WHERE
    events.eid = participants.eid
    AND participants.user = $user_quoted
    AND events.end_date >= ?
    AND (
            events.start_date < ?
        OR
            events.start_date = ?
            AND (
                    events.start_time < '01:00:00'
                OR
                    events.start_time IS NULL
            )
    )
ORDER BY events.start_date, events.start_time
EOF

        # The two statements above take as input:
        # 1) The current date
        # 2) The current date
        # 3) The current date

        # Find the events happening between a given hour and hour + 1.
        my $sth_events = $dbh->prepare( <<EOF );
SELECT eid, name, start_date, start_time, end_date, end_time, description, reminder, rid
FROM events
WHERE
    initiator = $user_quoted
    AND start_date = ?
    AND start_time >= ?
    AND start_time <= ?
ORDER BY start_date, start_time
EOF
        my $sth_participants = $dbh->prepare( <<EOF );
SELECT events.eid, events.name, events.start_date, events.start_time, events.end_date, events.end_time, events.description, participants.reminder, events.rid, participants.status
FROM events, participants
WHERE
    events.eid = participants.eid
    AND participants.user = $user_quoted
    AND events.start_date = ?
    AND events.start_time >= ?
    AND events.start_time <= ?
ORDER BY events.start_date, events.start_time
EOF

        # The two statements above take as input:
        # 1) The current date
        # 2) The current hour
        # 3) The current hour + 59:59

        # Is there any attachment associated with this event?
        my $sth_attach = $dbh->prepare( <<EOF );
SELECT COUNT(*)
FROM attachments
WHERE
    eid = ?
EOF

        foreach my $hour ( 0 .. 23 ) {
            my $class;
            if (    $year == $to_year
                and $month == $to_month
                and $day == $to_day
                and $hour == $to_hour )
            {
                $class = 'dayviewcurhour';
            } else {
                $class = 'dayviewhour';
            }
            $return .= <<EOF;
    <tr>
        <td class=$class><a href="$uri?action=editevent&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day&amp;hour=$hour">$hour:00</a></td>
EOF

            my @sths;

            my $today_date = to_date( $year, $month, $day );
            my $curhour_time = to_time($hour);
            my $nexthour_time = to_time( $hour, 59, 59 );
            if ( $hour == 0 ) {
                $sth_events_first_hour->execute( $today_date, $today_date,
                    $today_date );
                $sth_participants_first_hour->execute( $today_date, $today_date,
                    $today_date );
                @sths =
                  ( $sth_events_first_hour, $sth_participants_first_hour );
            } else {
                $sth_events->execute( $today_date, $curhour_time,
                    $nexthour_time );
                $sth_participants->execute( $today_date, $curhour_time,
                    $nexthour_time );
                @sths = ( $sth_events, $sth_participants );
            }

            foreach my $sth (@sths) {
                while (
                    my (
                        $eid,      $name,     $start_date,  $start_time,
                        $end_date, $end_time, $description, $reminder,
                        $rid,      $status
                    )
                    = $sth->fetchrow_array
                  )
                {
                    my ( $syear, $smonth, $sday, $shour, $smin, $ssec ) =
                      ( from_date($start_date), from_time($start_time) );
                    my ( $eyear, $emonth, $eday, $ehour, $emin, $esec ) =
                      ( from_date($end_date), from_time($end_time) );

                    my $rowspan;
                    if ( defined $start_time ) {
                        my ( $start_row, $end_row ) =
                          ( $shour, $ehour - ( $emin > 0 ? 0 : 1 ) );
                        if (
                            Compare_YMD( $syear, $smonth, $sday, $year, $month,
                                $day ) == -1
                          )
                        {
                            $start_row = 0;
                        }
                        if (
                            Compare_YMD( $eyear, $emonth, $eday, $year, $month,
                                $day ) == 1
                          )
                        {
                            $end_row = 23;
                        }
                        $rowspan = $end_row - $start_row + 1;
                    } else {
                        $rowspan = 24;
                    }

                    my $format;
                    if ( defined $start_time ) {
                        if (
                            Compare_YMD(
                                $syear, $smonth, $sday,
                                $eyear, $emonth, $eday
                            ) == 0
                          )
                        {
                            $format = $conf->{DAY_DATE_FORMAT};
                        } else {
                            $format = $conf->{DAY_MULTIDAY_DATE_FORMAT};
                        }
                    } elsif (
                        Compare_YMD( $syear, $smonth, $sday, $eyear, $emonth,
                            $eday ) != 0
                      )
                    {
                        $format = $conf->{DAY_MULTIDAY_NOTIME_DATE_FORMAT};
                    } else {
                        $format = $conf->{DAY_NOTIME_DATE_FORMAT};
                    }
                    my $range = $format
                      ? encode_entities(
                        sprintf '%s - %s ',
                        $chronos->format_date(
                            $format, $syear, $smonth, $sday,
                            $shour,  $smin,  0
                        ),
                        $chronos->format_date(
                            $format, $eyear, $emonth, $eday,
                            $ehour,  $emin,  0
                        )
                      )
                      : '';

                    my $status_text;
                    my $textkey = "status_$status";
                    if ($status) {
                        $status_text = "<br><b>$text->{$textkey}</b>";
                    }
                    $description = encode_entities($description);
                    $description =~ s/\n/<br>/g;

                    # make all links in the description clickable
                    my $finder = URI::Find::Schemeless->new(
                        sub {
                            my ( $uri, $orig_uri ) = @_;
                            return
                              qq|<a href="$uri" target=_blank>$orig_uri</a>|;
                        }
                    );
                    $finder->find( \$description );
                    # same thing for email addresses
                    $description =~
s/(\w[\w.-]+\@\w[\w.-]*\.[\w]+)/<a href="mailto:$1">$1<\/a>/g;

                    my $recur =
                      defined $rid
                      ? "<img src=\"/chronos_static/recur.png\"> "
                      : '';

                    my $bell =
                      defined $reminder
                      ? "<img src=\"/chronos_static/bell.png\"> "
                      : '';

                    $sth_attach->execute($eid);
                    my $file =
                      $sth_attach->fetchrow_array
                      ? "<img src=\"/chronos_static/file.png\"> "
                      : '';
                    $sth_attach->finish;

                    $return .= <<EOF;
        <td class=event rowspan=$rowspan>$recur$bell$file$range<a class=event href="$uri?action=editevent&amp;eid=$eid&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day">$name</a>$status_text<br>$description</td>
EOF
                }
                $sth->finish;
            }

            $sth_simul_events->execute(
                $today_date, $today_date,   $nexthour_time, $today_date,
                $today_date, $curhour_time, $curhour_time
            );
            $sth_simul_participants->execute(
                $today_date, $today_date,   $nexthour_time, $today_date,
                $today_date, $curhour_time, $curhour_time
            );
            $return .=
              <<EOF x ( $max_simul_events - ( $sth_simul_events->fetchrow_array + $sth_simul_participants->fetchrow_array ) );
        <td class=dayview>&nbsp;</td>
EOF
            $sth_simul_events->finish;
            $sth_simul_participants->finish;

            $return .= <<EOF;
    </tr>
EOF
        }
    }

    $return .= <<EOF;
</table>

<table style="border:none">
    <tr>
        <td width=50 align=center><img src="/chronos_static/up.png"></td>
        <td></td>
    </tr>
    <tr>
        <td colspan=2><font size="-1">$text->{clickhour}</font></td>
    </tr>
</table>
<!-- End Chronos::Action::Showday::dayview -->
EOF

    return $return;
}

1;

# vim: set et ts=4 sw=4 ft=perl:
