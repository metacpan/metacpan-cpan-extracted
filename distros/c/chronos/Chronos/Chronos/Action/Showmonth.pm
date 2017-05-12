# $Id: Showmonth.pm,v 1.3 2002/08/28 19:15:29 nomis80 Exp $
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
package Chronos::Action::Showmonth;

use strict;
use Chronos::Action;
use Date::Calc qw(:all);
use HTML::Entities;
use Date::Calendar::Profiles qw($Profiles);
use Date::Calendar;

our @ISA = qw(Chronos::Action);

sub type {
    return 'read';
}

our %month_abbr =
  ( fr => [ undef, qw(Jan Fév Mar Avr Mai Jun Jul Aoû Sep Oct Nov Déc) ], );

sub header {
    my $self    = shift;
    my $object  = $self->object;
    my $chronos = $self->{parent};
    my ( $year, $month, $day ) = $chronos->day;
    my $lang   = $chronos->lang;
    my $text   = $chronos->gettext;
    my $uri    = $chronos->{r}->uri;
    my $return = <<EOF;
<!-- Begin Chronos::Action::Showmonth header -->
<table style="margin-style:none" cellspacing=0 cellpadding=0 width="100%">
    <tr>
        <td class=header>
            <table style="border:none" cellspacing=0 cellpadding=2>
EOF

    foreach my $row ( 0, 1 ) {
        $return .= <<EOF;
                <tr>
EOF
        foreach my $col ( 1 .. 6 ) {
            my $m          = 6 * $row + $col;
            my $month_text = encode_entities(
                substr(
                    (
                        $month_abbr{$lang}
                        ? $month_abbr{$lang}[$m]
                        : ucfirst Month_to_Text($m)
                    ),
                    0, 3
                )
            );
            $return .= <<EOF;
                    <td class=header><a href="$uri?action=showmonth&amp;object=$object&amp;year=$year&amp;month=$m&amp;day=$day">$month_text</a></td>
EOF
        }
        $return .= <<EOF;
                </tr>
EOF
    }
    $return .= <<EOF;
            </table>
        </td>
        <td class=header align=right>
            <a href="$uri?action=showweek&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day"><img src="/chronos_static/showweek.png" border=0>$text->{week}</a> |
            <a href="$uri?action=showday&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day"><img src="/chronos_static/showday.png" border=0>$text->{Day}</a>
        </td>
    </tr>
</table>
<!-- End Chronos::Action::Showmonth header -->
EOF
    return $return;
}

# Beaucoup de code dans cette fontion est emprunté de Chronos::minimonth(). S'il y
# a un bug ici, il doit sûrement y en avoir un aussi dans Chronos::minimonth().
sub content {
    my $self    = shift;
    my $object  = $self->object;
    my $chronos = $self->{parent};
    my ( $year, $month, $day ) = $chronos->day;
    my $uri = $chronos->{r}->uri;

    my ( $prev_year, $prev_month, $prev_day ) =
      Add_Delta_YM( $year, $month, $day, 0, -1 );
    my ( $next_year, $next_month, $next_day ) =
      Add_Delta_YM( $year, $month, $day, 0, 1 );
    my ( $prev_prev_year, $prev_prev_month, $prev_prev_day ) =
      Add_Delta_YM( $year, $month, $day, -1, 0 );
    my ( $next_next_year, $next_next_month, $next_next_day ) =
      Add_Delta_YM( $year, $month, $day, 1, 0 );

    my $return = <<EOF;
<!-- Begin Chronos::Showmonth body -->
<table width="100%" class=minimonth>
    <tr>
        <th class=minimonth colspan=7>
            <a class=minimonthheader href="$uri?action=showmonth&amp;object=$object&amp;year=$prev_prev_year&amp;month=$prev_prev_month&amp;day=$prev_prev_day"><img src="/chronos_static/back2.png" border=0></a>&nbsp;
            <a class=minimonthheader href="$uri?action=showmonth&amp;object=$object&amp;year=$prev_year&amp;month=$prev_month&amp;day=$prev_day"><img src="/chronos_static/back.png" border=0></a>&nbsp;
            @{[encode_entities(ucfirst Month_to_Text($month))]} $year&nbsp;
            <a class=minimonthheader href="$uri?action=showmonth&amp;object=$object&amp;year=$next_year&amp;month=$next_month&amp;day=$next_day"><img src="/chronos_static/forward.png" border=0></a>&nbsp;
            <a class=minimonthheader href="$uri?action=showmonth&amp;object=$object&amp;year=$next_next_year&amp;month=$next_next_month&amp;day=$next_next_day"><img src="/chronos_static/forward2.png" border=0></a>
        </th>
    </tr>
    <tr>
EOF

    foreach ( 1 .. 7 ) {
        $return .= <<EOF;
        <td width="14%">@{[encode_entities(Day_of_Week_to_Text($_))]}</td>
EOF
    }

    $return .= <<EOF;
    </tr>
EOF

    my $dow_first = Day_of_Week( $year, $month, 1 );
    if ( $dow_first != 1 ) {
        $return .= <<EOF;
    <tr>
EOF
    }
    foreach ( 1 .. ( $dow_first - 1 ) ) {
        my ( $mini_year, $mini_month, $mini_day ) =
          Add_Delta_Days( $year, $month, 1, -( $dow_first - $_ ) );
        my $holidays =
          $self->get_holidays( $mini_year, $mini_month, $mini_day );
        $return .= <<EOF;
        <td class=dayothermonth height=80><a class=daycurmonth href="$uri?action=showday&amp;object=$object&amp;year=$mini_year&amp;month=$mini_month&amp;day=$mini_day">$mini_day</a>$holidays
EOF
        $return .= $chronos->events_per_day( 'month', $mini_year, $mini_month,
            $mini_day );
        $return .= "</td>";
    }

    my $days = Days_in_Month( $year, $month );
    my ( $curyear, $curmonth, $curday ) = Today();
    foreach ( 1 .. $days ) {
        my $class =
          ( $_ == $curday and $month == $curmonth and $year == $curyear )
          ? 'today'
          : 'daycurmonth';

        my $dow = Day_of_Week( $year, $month, $_ );
        if ( $dow == 1 ) {
            $return .= <<EOF;
    <tr>
EOF
        }

        my $holidays = $self->get_holidays( $year, $month, $_ );
        $return .= <<EOF;
        <td class=daycurmonth height=80><a class=$class href="$uri?action=showday&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$_">$_</a>$holidays
EOF

        $return .= $chronos->events_per_day( 'month', $year, $month, $_ );

        $return .= <<EOF;
        </td>
EOF
        if ( $dow == 7 ) {
            $return .= <<EOF;
    </tr>
EOF
        }
    }

    my $dow_last = Day_of_Week( $year, $month, $days );
    foreach ( ( $dow_last + 1 ) .. 7 ) {
        my ( $mini_year, $mini_month, $mini_day ) =
          Add_Delta_Days( $year, $month, $days, ( $_ - $dow_last ) );
        my $holidays =
          $self->get_holidays( $mini_year, $mini_month, $mini_day );
        $return .= <<EOF;
        <td class=dayothermonth height=80><a class=daycurmonth href="$uri?action=showday&amp;object=$object&amp;year=$mini_year&amp;month=$mini_month&amp;day=$mini_day">$mini_day</a>$holidays
EOF
        $return .= $chronos->events_per_day( 'month', $mini_year, $mini_month,
            $mini_day );
        $return .= "</td>";
    }

    $return .= <<EOF;
    </tr>
</table>
<!-- End Chronos::Action::Showmonth body -->
EOF
    return $return;
}

{
    # Cache calendars per year/profile because it is too slow otherwise
    my %calendars;

    sub get_holidays {
        my $self = shift;
        my ( $year, $month, $day ) = @_;
        my $profile = $self->{parent}->conf->{HOLIDAYS};
        return '' if not $profile;
        if ( not $calendars{$profile}{$year} ) {
            $calendars{$profile}{$year} =
              Date::Calendar->new( $Profiles->{$profile} )->year($year);
        }
        my @holidays =
          $calendars{$profile}{$year}->labels( $year, $month, $day );
        shift @holidays;
        encode_entities($_) foreach @holidays;
        if (@holidays) {
            return "<br>" . join ( "<br>", @holidays );
        } else {
            return '';
        }
    }
}

1;

# vim: set et ts=4 sw=4 ft=perl:
