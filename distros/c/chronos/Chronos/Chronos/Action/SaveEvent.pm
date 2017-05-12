# $Id: SaveEvent.pm,v 1.3 2002/08/27 18:46:30 nomis80 Exp $
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
package Chronos::Action::SaveEvent;

use strict;
use Chronos::Action;
use Date::Calc qw(:all);
use Chronos::Static
  qw(Compare_YMDHMS Compare_YMD userstring to_datetime to_date to_time from_date from_time);
use HTML::Entities;

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
    my $text    = $chronos->gettext;

    my $eid = $chronos->{r}->param('eid');

    my $redirect;

    if ($eid) {
        # Modification d'un événement existant
        if (
            $dbh->selectrow_array(
                "SELECT initiator FROM events WHERE eid = $eid"
            ) eq $self->object
          )
        {
            # On est exécuté par l'initiateur de l'événement. On peut faire des actions privilégiées.
            if ( $chronos->{r}->param('delete') ) {
                # Suppression d'événement
                my $sth_delete_participants =
                  $dbh->prepare("DELETE FROM participants WHERE eid = ?");
                my $sth_delete_attachments =
                  $dbh->prepare("DELETE FROM attachments WHERE eid = ?");
                my $sth_delete_events =
                  $dbh->prepare("DELETE FROM events WHERE eid = ?");
                my $rid =
                  $dbh->selectrow_array(
                    "SELECT rid FROM events WHERE eid = $eid");
                if ($rid) {
                    my $sth =
                      $dbh->prepare("SELECT eid FROM events WHERE rid = $rid");
                    $sth->execute;
                    while ( my $eid = $sth->fetchrow_array ) {
                        $sth_delete_participants->execute($eid);
                        $sth_delete_events->execute($eid);
                        $sth_delete_attachments->execute($eid);
                    }
                    $sth->finish;
                    $dbh->do("DELETE FROM recur WHERE rid = $rid");
                } else {
                    $sth_delete_participants->execute($eid);
                    $sth_delete_events->execute($eid);
                    $sth_delete_attachments->execute($eid);
                }
            } else {
                my $sth = $dbh->prepare("SELECT user FROM user");
                $sth->execute;
                my $removed_participant;
                while ( my $user = $sth->fetchrow_array ) {
                    if ( $chronos->{r}->param("remove_$user") ) {
                        # Suppression d'un participant par l'initiateur de l'événement
                        $dbh->prepare(
"DELETE FROM participants WHERE user = ? AND eid = ?"
                        )->execute( $user, $eid );
                        $removed_participant = 1;
                        $redirect            = 'self';
                        last;
                    }
                }
                $sth->finish;

                if ( not $removed_participant ) {
                    # Modification de la table events par l'initiateur de l'événement
                    my $name        = $chronos->{r}->param('name');
                    my $notime      = $chronos->{r}->param('notime') ? 1 : 0;
                    my $start_month = $chronos->{r}->param('start_month');
                    my $start_day   = $chronos->{r}->param('start_day');
                    my $start_year  = $chronos->{r}->param('start_year');
                    my $start_hour  =
                      $notime ? undef: $chronos->{r}->param('start_hour');
                    my $start_min =
                      $notime ? undef: $chronos->{r}->param('start_min');
                    my $end_month = $chronos->{r}->param('end_month');
                    my $end_day   = $chronos->{r}->param('end_day');
                    my $end_year  = $chronos->{r}->param('end_year');
                    my $end_hour  =
                      $notime ? undef: $chronos->{r}->param('end_hour');
                    my $end_min =
                      $notime ? undef: $chronos->{r}->param('end_min');
                    my $description     = $chronos->{r}->param('description');
                    my $confirm         = $chronos->{r}->param('confirm');
                    my $reminder_number =
                      $chronos->{r}->param('reminder_number');
                    my $reminder_unit = $chronos->{r}->param('reminder_unit');
                    my @participants  = $chronos->{r}->param('participants');
                    $redirect = 'self' if @participants;

                    $self->error('startdate')
                      unless check_date( $start_year, $start_month,
                        $start_day );
                    $self->error('starttime')
                      unless $notime
                      or check_time( $start_hour, $start_min, 0 );
                    $self->error('enddate')
                      unless check_date( $end_year, $end_month, $end_day );
                    $self->error('endtime')
                      unless $notime
                      or check_time( $end_hour, $end_min, 0 );

                    $self->error('endbeforestart')
                      if Compare_YMDHMS(
                        $start_year, $start_month, $start_day, $start_hour,
                        $start_min,  0,            $end_year,  $end_month,
                        $end_day,    $end_hour,    $end_min,   0
                      ) == 1;

                    $name or $self->error('missingname');

                    my $status = $confirm ? 'UNCONFIRMED' : undef;

                    # Tout a l'air beau, on fait l'update
                    my $sth_participants =
                      $dbh->prepare(
"INSERT INTO participants (eid, user, status) VALUES(?, ?, ?)"
                      );
                    if (
                        my $rid = $dbh->selectrow_array(
                            "SELECT rid FROM events WHERE eid = $eid"
                        )
                      )
                    {
                        $dbh->prepare(
"UPDATE events SET name = ?, description = ? WHERE rid = ?"
                        )->execute( $name, $description, $rid );

                        my $first_eid =
                          $dbh->selectrow_array(
"SELECT eid FROM events WHERE rid = $rid ORDER BY eid LIMIT 1"
                          );
                        my ( $start_date, $start_time, $end_date, $end_time ) =
                          $dbh->selectrow_array(
"SELECT start_date, start_time, end_date, end_time FROM events WHERE eid = $eid"
                          );
                        my ( $Dsyear, $Dsmonth, $Dsday, $Dshour, $Dsmin ) =
                          Delta_YMDHMS(
                            from_date($start_date), from_time($start_time),
                            $start_year,            $start_month,
                            $start_day,             $start_hour,
                            $start_min,             0
                          );
                        my ( $Deyear, $Demonth, $Deday, $Dehour, $Demin ) =
                          Delta_YMDHMS(
                            from_date($end_date), from_time($end_time),
                            $end_year,            $end_month,
                            $end_day,             $end_hour,
                            $end_min,             0
                          );

                        my @delta_reminder = ( 0, 0, 0, 0 );
                        if ( $reminder_number ne '-' ) {
                            if ( $reminder_unit eq 'min' ) {
                                $delta_reminder[2] = -$reminder_number;
                            } elsif ( $reminder_unit eq 'hour' ) {
                                $delta_reminder[1] = -$reminder_number;
                            } else {
                                $delta_reminder[0] = -$reminder_number;
                            }
                        }

                        my $sth_update =
                          $dbh->prepare(
"UPDATE events SET start_date = ?, start_time = ?, end_date = ?, end_time = ?, reminder = ? WHERE eid = ?"
                          );
                        my $sth_eid =
                          $dbh->prepare(
"SELECT eid, start_date, start_time, end_date, end_time FROM events WHERE rid = $rid"
                          );
                        $sth_eid->execute;
                        while (
                            my (
                                $eid,      $start_date, $start_time,
                                $end_date, $end_time
                            )
                            = $sth_eid->fetchrow_array
                          )
                        {
                            my ( $syear, $smonth, $sday, $shour, $smin ) =
                              Add_Delta_YMDHMS(
                                from_date($start_date),
                                from_time($start_time),
                                $Dsyear,
                                $Dsmonth,
                                $Dsday,
                                $Dshour,
                                $Dsmin,
                                0
                              );
                            my ( $eyear, $emonth, $eday, $ehour, $emin ) =
                              Add_Delta_YMDHMS( from_date($end_date),
                                from_time($end_time), $Deyear, $Demonth, $Deday,
                                $Dehour, $Demin, 0 );
                            my $reminder =
                              $reminder_number eq '-'
                              ? undef
                              : to_datetime(
                                Add_Delta_DHMS(
                                    $syear, $smonth, $sday,
                                    $shour, $smin,   0,
                                    @delta_reminder
                                )
                              );
                            $sth_update->execute(
                                to_date( $syear, $smonth, $sday ),
                                (
                                    $notime ? undef: to_time( $shour, $smin, 0 )
                                ),
                                to_date( $eyear, $emonth, $eday ),
                                (
                                    $notime ? undef: to_time( $ehour, $emin, 0 )
                                ),
                                $reminder,
                                $eid
                            );
                            foreach (@participants) {
                                $sth_participants->execute( $eid, $_, $status );
                            }
                        }
                        $sth_eid->finish;
                    } else {
                        my $start_date =
                          to_date( $start_year, $start_month, $start_day );
                        my $start_time =
                          $notime ? undef: to_time( $start_hour, $start_min );
                        my $end_date =
                          to_date( $end_year, $end_month, $end_day );
                        my $end_time =
                          $notime ? undef: to_time( $end_hour, $end_min );

                        my $reminder;
                        if ( $reminder_number ne '-' ) {
                            my ( $remind_year, $remind_month, $remind_day,
                                $remind_hour, $remind_min, $Dd, $Dh, $Dm, );
                            if ( $reminder_unit eq 'min' ) {
                                $Dm = -$reminder_number;
                            } elsif ( $reminder_unit eq 'hour' ) {
                                $Dh = -$reminder_number;
                            } else {
                                $Dd = -$reminder_number;
                            }
                            (
                                $remind_year, $remind_month, $remind_day,
                                $remind_hour, $remind_min
                              )
                              = Add_Delta_DHMS(
                                $start_year, $start_month,
                                $start_day,  $start_hour,
                                $start_min,  0,
                                $Dd,         $Dh,
                                $Dm,         0
                              );
                            $reminder = sprintf '%04d-%02d-%02d %02d:%02d:00',
                              $remind_year, $remind_month, $remind_day,
                              $remind_hour, $remind_min;
                        }

                        $dbh->prepare(
"UPDATE events SET name = ?, start_date = ?, start_time = ?, end_date = ?, end_time = ?, description = ?, reminder = ? WHERE eid = $eid"
                          )->execute(
                            $name,     $start_date, $start_time,
                            $end_date, $end_time,   $description,
                            $reminder
                          );
                        foreach (@participants) {
                            $sth_participants->execute( $eid, $_, $status );
                        }
                    }

                    if ($confirm) {
                        $self->send_mails(
                            $start_year,  $start_month, $start_day,
                            $start_hour,  $start_min,   $name,
                            $description, $eid,         @participants
                        );
                    }

                    if ( $chronos->{r}->param('new_attachment') ) {
                        my $upload   = $chronos->{r}->upload('new_attachment');
                        my $filename = $upload->filename;
                        $filename =~ s/.*\///;
                        $filename =~ s/.*\\//;
                        my $size = $upload->size;
                        my $file;
                        {
                            local $/;
                            $file = readline $upload->fh;
                        }
                        $dbh->prepare(
"INSERT INTO attachments (filename, size, file, eid) VALUES(?, ?, ?, ?)"
                        )->execute( $filename, $size, $file, $eid );
                    }
                }
            }
        } elsif ( $chronos->{r}->param('confirm') ) {
            # Confirmation de la part d'un participant
            my $sth =
              $dbh->prepare(
"UPDATE participants SET status = 'CONFIRMED' WHERE eid = ? AND user = ?"
              );
            if (
                my $rid = $dbh->selectrow_array(
                    "SELECT rid FROM events WHERE eid = $eid"
                )
              )
            {
                my $sth_eid =
                  $dbh->prepare("SELECT eid FROM events WHERE rid = $rid");
                $sth_eid->execute;
                while ( my $eid = $sth_eid->fetchrow_array ) {
                    $sth->execute( $eid, $self->object );
                }
                $sth_eid->finish;
            } else {
                $sth->execute( $eid, $self->object );
            }
        } elsif ( $chronos->{r}->param('cancel') ) {
            # Annulation de la part d'un participant
            my $sth =
              $dbh->prepare(
"UPDATE participants SET status = 'CANCELED' WHERE eid = ? AND user = ?"
              );
            if (
                my $rid = $dbh->selectrow_array(
                    "SELECT rid FROM events WHERE eid = $eid"
                )
              )
            {
                my $sth_eid =
                  $dbh->prepare("SELECT eid FROM events WHERE rid = $rid");
                $sth_eid->execute;
                while ( my $eid = $sth_eid->fetchrow_array ) {
                    $sth->execute( $eid, $self->object );
                }
                $sth_eid->finish;
            } else {
                $sth->execute( $eid, $self->object );
            }
        } else {
            # Changement du reminder ou d'un attachment par un participant
            my $reminder_number = $chronos->{r}->param('reminder_number');
            my $reminder_unit   = $chronos->{r}->param('reminder_unit');

            if (
                my $rid = $dbh->selectrow_array(
                    "SELECT rid FROM events WHERE eid = $eid"
                )
              )
            {
                my @reminder_delta = ( 0, 0, 0, 0 );
                if ( $reminder_unit eq 'min' ) {
                    $reminder_delta[2] = -$reminder_number;
                } elsif ( $reminder_unit eq 'hour' ) {
                    $reminder_delta[1] = -$reminder_number;
                } else {
                    $reminder_delta[0] = -$reminder_number;
                }

                my $sth_update =
                  $dbh->prepare(
"UPDATE participants SET reminder = ? WHERE eid = ? AND user = ?"
                  );

                my $sth_eid =
                  $dbh->prepare(
"SELECT eid, start_date, start_time FROM events WHERE rid = $rid"
                  );
                $sth_eid->execute;
                while ( my ( $eid, $start_date, $start_time ) =
                    $sth_eid->fetchrow_array )
                {
                    my $reminder = $reminder_number eq '-' ? undef: to_datetime(
                        Add_Delta_DHMS(
                            from_date($start_date), from_time($start_time),
                            @reminder_delta
                        )
                    );
                    $sth_update->execute( $reminder, $eid, $self->object );
                }
                $sth_eid->finish;
            } else {
                my ( $start_date, $start_time ) =
                  $dbh->selectrow_array(
                    "SELECT start_date, start_time FROM events WHERE eid = $eid"
                  );
                my ( $syear, $smonth, $sday, $shour, $smin ) =
                  from_date($start_date), from_time($start_time);
                my $reminder;
                if ( $reminder_number ne '-' ) {
                    my ( $remind_year, $remind_month, $remind_day, $remind_hour,
                        $remind_min, $Dd, $Dh, $Dm, );
                    if ( $reminder_unit eq 'min' ) {
                        $Dm = -$reminder_number;
                    } elsif ( $reminder_unit eq 'hour' ) {
                        $Dh = -$reminder_number;
                    } else {
                        $Dd = -$reminder_number;
                    }
                    (
                        $remind_year, $remind_month, $remind_day,
                        $remind_hour, $remind_min
                      )
                      = Add_Delta_DHMS(
                        $syear, $smonth, $sday, $shour, $smin, 0,
                        $Dd,    $Dh,     $Dm,   0
                      );
                    $reminder = sprintf '%04d-%02d-%02d %02d:%02d:00',
                      $remind_year, $remind_month, $remind_day, $remind_hour,
                      $remind_min;
                }
                $dbh->prepare(
"UPDATE participants SET reminder = ? WHERE eid = ? AND user = ?"
                )->execute( $reminder, $eid, $self->object );
            }

            if ( $chronos->{r}->param('new_attachment') ) {
                my $upload   = $chronos->{r}->upload('new_attachment');
                my $filename = $upload->filename;
                $filename =~ s/.*\///;
                $filename =~ s/.*\\//;
                my $size = $upload->size;
                my $file;
                {
                    local $/;
                    $file = readline $upload->fh;
                }
                $dbh->prepare(
"INSERT INTO attachments (filename, size, file, eid) VALUES(?, ?, ?, ?)"
                )->execute( $filename, $size, $file, $eid );
            }
        }
    } else {
        # Création d'événement
        my $name        = $chronos->{r}->param('name');
        my $notime      = $chronos->{r}->param('notime') ? 1 : 0;
        my $start_month = $chronos->{r}->param('start_month');
        my $start_day   = $chronos->{r}->param('start_day');
        my $start_year  = $chronos->{r}->param('start_year');
        my $start_hour = $notime ? undef: $chronos->{r}->param('start_hour');
        my $start_min  = $notime ? undef: $chronos->{r}->param('start_min');
        my $end_month       = $chronos->{r}->param('end_month');
        my $end_day         = $chronos->{r}->param('end_day');
        my $end_year        = $chronos->{r}->param('end_year');
        my $end_hour        = $notime ? undef: $chronos->{r}->param('end_hour');
        my $end_min         = $notime ? undef: $chronos->{r}->param('end_min');
        my $description     = $chronos->{r}->param('description');
        my $recur           = $chronos->{r}->param('recur');
        my $recur_end_month = $chronos->{r}->param('recur_end_month');
        my $recur_end_day   = $chronos->{r}->param('recur_end_day');
        my $recur_end_year  = $chronos->{r}->param('recur_end_year');
        my $confirm         = $chronos->{r}->param('confirm');
        my $reminder_number = $chronos->{r}->param('reminder_number');
        my $reminder_unit   = $chronos->{r}->param('reminder_unit');
        my @participants    = $chronos->{r}->param('participants');

        $self->error('startdate')
          unless check_date( $start_year, $start_month, $start_day );
        $self->error('starttime')
          unless $notime
          or check_time( $start_hour, $start_min, 0 );
        $self->error('enddate')
          unless check_date( $end_year, $end_month, $end_day );
        $self->error('endtime')
          unless $notime
          or check_time( $end_hour, $end_min, 0 );
        $self->error('recurenddate')
          unless check_date( $recur_end_year, $recur_end_month,
            $recur_end_day );

        $self->error('endbeforestart')
          if Compare_YMDHMS(
            $start_year, $start_month, $start_day, $start_hour,
            $start_min,  0,            $end_year,  $end_month,
            $end_day,    $end_hour,    $end_min,   0
          ) == 1;
        $self->error('recurendbeforestart')
          if $recur ne 'NULL'
          and Compare_YMD(
            $start_year,     $start_month,     $start_day,
            $recur_end_year, $recur_end_month, $recur_end_day
          ) == 1;
        $self->error('recurendbeforeend')
          if $recur ne 'NULL'
          and Compare_YMD( $end_year, $end_month, $end_day, $recur_end_year,
            $recur_end_month, $recur_end_day, ) == 1;
        $self->error('missingname') unless $name;

        my $new_eid;

        # Tout a l'air beau, on fait le insert.
        if ( $recur ne 'NULL' ) {
            my (
                $syear, $smonth, $sday, $shour, $smin,
                $eyear, $emonth, $eday, $ehour, $emin
              )
              = (
                $start_year, $start_month, $start_day, $start_hour,
                $start_min,  $end_year,    $end_month, $end_day,
                $end_hour,   $end_min
              );
            my $recur_end =
              to_date( $recur_end_year, $recur_end_month, $recur_end_day );

            $dbh->prepare("INSERT INTO recur (every, last) VALUES(?, ?)")
              ->execute( $recur, $recur_end );
            my $rid = $dbh->selectrow_array("SELECT LAST_INSERT_ID()");

            my $sth =
              $dbh->prepare(
"INSERT INTO events (initiator, name, start_date, start_time, end_date, end_time, description, rid, reminder) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)"
              );
            my $sth_participants =
              $dbh->prepare(
                "INSERT INTO participants (eid, user, status) VALUES(?, ?, ?)");

            my $status = $confirm ? 'UNCONFIRMED' : undef;

            while (
                Compare_YMD(
                    $syear,          $smonth,          $sday,
                    $recur_end_year, $recur_end_month, $recur_end_day
                ) != 1
              )
            {
                my $start_date = to_date( $syear, $smonth, $sday );
                my $start_time = $notime ? undef: to_time( $shour, $smin, 0 );
                my $end_date = to_date( $eyear, $emonth, $eday );
                my $end_time = $notime ? undef: to_time( $ehour, $emin, 0 );

                my $reminder;
                if ( $reminder_number ne '-' ) {
                    my ( $remind_year, $remind_month, $remind_day, $remind_hour,
                        $remind_min, $Dd, $Dh, $Dm, );
                    if ( $reminder_unit eq 'min' ) {
                        $Dm = -$reminder_number;
                    } elsif ( $reminder_unit eq 'hour' ) {
                        $Dh = -$reminder_number;
                    } else {
                        $Dd = -$reminder_number;
                    }
                    (
                        $remind_year, $remind_month, $remind_day,
                        $remind_hour, $remind_min
                      )
                      = Add_Delta_DHMS(
                        $syear, $smonth, $sday, $shour, $smin, 0,
                        $Dd,    $Dh,     $Dm,   0
                      );
                    $reminder = sprintf '%04d-%02d-%02d %02d:%02d:00',
                      $remind_year, $remind_month, $remind_day, $remind_hour,
                      $remind_min;
                }

                $sth->execute(
                    $self->object, $name,     $start_date,
                    $start_time,   $end_date, $end_time,
                    $description,  $rid,      $reminder
                );
                my $eid = $dbh->selectrow_array("SELECT LAST_INSERT_ID()");
                $new_eid ||= $eid;
                foreach (@participants) {
                    $sth_participants->execute( $eid, $_, $status );
                }

                if ( $chronos->{r}->param('new_attachment') ) {
                    my $upload   = $chronos->{r}->upload('new_attachment');
                    my $filename = $upload->filename;
                    $filename =~ s/.*\///;
                    $filename =~ s/.*\\//;
                    my $size = $upload->size;
                    my $file;
                    {
                        local $/;
                        $file = readline $upload->fh;
                    }
                    $dbh->prepare(
"INSERT INTO attachments (filename, size, file, eid) VALUES(?, ?, ?, ?)"
                    )->execute( $filename, $size, $file, $eid );
                }

                if ( $recur eq 'DAY' ) {
                    ( $syear, $smonth, $sday ) =
                      Add_Delta_Days( $syear, $smonth, $sday, 1 );
                    ( $eyear, $emonth, $eday ) =
                      Add_Delta_Days( $eyear, $emonth, $eday, 1 );
                } elsif ( $recur eq 'WEEK' ) {
                    ( $syear, $smonth, $sday ) =
                      Add_Delta_Days( $syear, $smonth, $sday, 7 );
                    ( $eyear, $emonth, $eday ) =
                      Add_Delta_Days( $eyear, $emonth, $eday, 7 );
                } elsif ( $recur eq 'MONTH' ) {
                    ( $syear, $smonth, $sday ) =
                      Add_Delta_YM( $syear, $smonth, $sday, 0, 1 );
                    ( $eyear, $emonth, $eday ) =
                      Add_Delta_YM( $eyear, $emonth, $eday, 0, 1 );
                } elsif ( $recur eq 'YEAR' ) {
                    ( $syear, $smonth, $sday ) =
                      Add_Delta_YM( $syear, $smonth, $sday, 1, 0 );
                    ( $eyear, $emonth, $eday ) =
                      Add_Delta_YM( $eyear, $emonth, $eday, 1, 0 );
                } else {
                    last;
                }
            }
        } else {    # $recur eq 'NULL'
            my $start_date = to_date( $start_year, $start_month, $start_day );
            my $start_time =
              $notime ? undef: to_time( $start_hour, $start_min );
            my $end_date = to_date( $end_year, $end_month, $end_day );
            my $end_time = $notime ? undef: to_time( $end_hour, $end_min );

            my $reminder;
            if ( $reminder_number ne '-' ) {
                my ( $remind_year, $remind_month, $remind_day, $remind_hour,
                    $remind_min, $Dd, $Dh, $Dm, );
                if ( $reminder_unit eq 'min' ) {
                    $Dm = -$reminder_number;
                } elsif ( $reminder_unit eq 'hour' ) {
                    $Dh = -$reminder_number;
                } else {
                    $Dd = -$reminder_number;
                }
                (
                    $remind_year, $remind_month, $remind_day,
                    $remind_hour, $remind_min
                  )
                  = Add_Delta_DHMS(
                    $start_year, $start_month, $start_day, $start_hour,
                    $start_min,  0,            $Dd,        $Dh,
                    $Dm,         0
                  );
                $reminder = to_datetime(
                    $remind_year, $remind_month, $remind_day,
                    $remind_hour, $remind_min
                );
            }

            my $sth =
              $dbh->prepare(
"INSERT INTO events (initiator, name, start_date, start_time, end_date, end_time, description, reminder) VALUES(?, ?, ?, ?, ?, ?, ?, ?)"
              );
            $sth->execute(
                $self->object, $name,     $start_date,  $start_time,
                $end_date,     $end_time, $description, $reminder
            );

            my $eid = $dbh->selectrow_array("SELECT LAST_INSERT_ID()");
            $new_eid = $eid;
            my $status = $confirm ? 'UNCONFIRMED' : undef;
            $sth =
              $dbh->prepare(
"INSERT INTO participants (eid, user, status) VALUES($eid, ?, '$status')"
              );
            foreach (@participants) {
                $sth->execute($_);
            }

            if ( $chronos->{r}->param('new_attachment') ) {
                my $upload   = $chronos->{r}->upload('new_attachment');
                my $filename = $upload->filename;
                $filename =~ s/.*\///;
                $filename =~ s/.*\\//;
                my $size = $upload->size;
                my $file;
                {
                    local $/;
                    $file = readline $upload->fh;
                }
                $dbh->prepare(
"INSERT INTO attachments (filename, size, file, eid) VALUES(?, ?, ?, ?)"
                )->execute( $filename, $size, $file, $eid );
            }
        }

        if ($confirm) {
            $self->send_mails(
                $start_year,  $start_month, $start_day,
                $start_hour,  $start_min,   $name,
                $description, $new_eid,     @participants
            );
        }
    }

    my ( $year, $month, $day ) = $chronos->day;
    my $uri = $chronos->{r}->uri;
    if ( $chronos->{r}->param('eid') and $chronos->{r}->param('new_attachment')
        or $redirect eq 'self' )
    {
        $chronos->{r}->header_out( "Location",
"$uri?action=editevent&eid=$eid&object=$object&year=$year&month=$month&day=$day"
        );
    } else {
        $chronos->{r}->header_out( "Location",
"$uri?action=showday&object=$object&year=$year&month=$month&day=$day"
        );
    }
}

sub error {
    my $self    = shift;
    my $error   = shift;
    my $chronos = $self->{parent};
    $chronos->{r}->content_type('text/html');
    $chronos->{r}->send_http_header;
    my $text = $chronos->gettext;
    $error = $text->{"error$error"};
    $chronos->{r}->print(
"<html><head><title>$text->{error}</title></head><body><h1>$text->{error}</h1><p>$error</p></body></html>"
    );
    exit 0;
}

sub redirect {
    return 1;
}

sub send_mails {
    my (
        $self,       $start_year, $start_month, $start_day,
        $start_hour, $start_min,  $name,        $description,
        $eid,        @participants
      )
      = @_;
    my $chronos  = $self->{parent};
    my $text     = $chronos->gettext;
    my $dbh      = $chronos->dbh;
    my $sendmail = $chronos->conf->{SENDMAIL};
    my $uri      =
      ( exists $ENV{HTTPS} ? 'https' : 'http' ) . '://'
      . $chronos->{r}->hostname
      . $chronos->{r}->uri
      . "?action=editevent&eid=$eid";
    my ( $ini_name, $ini_email ) =
      $dbh->selectrow_array(
"SELECT name, email FROM user WHERE user = @{[$dbh->quote($self->object)]}"
      );
    my $sth = $dbh->prepare("SELECT email FROM user WHERE user = ?");

    foreach (@participants) {
        $sth->execute($_);
        my $email_addy = $sth->fetchrow_array;
        $sth->finish;
        my $mail_body  = $text->{confirm_body};
        my $userstring =
          decode_entities( userstring( $self->object, $ini_name, $ini_email ) );
        $userstring =~ s/<a.*?>(.*?)<\/a>/$1/;
        $mail_body  =~ s/\%\%INITIATOR\%\%/$userstring/;
        my $date = Date_to_Text_Long( $start_year, $start_month, $start_day )
          . (
            defined $start_hour
            ? sprintf( '%2d:%02d', $start_hour, $start_min )
            : ''
          );
        $mail_body =~ s/\%\%DATE\%\%/$date/;
        $mail_body =~ s/\%\%NAME\%\%/$name/;
        $mail_body =~ s/\%\%DESCRIPTION\%\%/$description/;
        $mail_body =~ s/\%\%VERSION\%\%/$chronos->VERSION/e;
        $mail_body =~ s/\%\%CONFIRMURL\%\%/$uri/;
        my $subject = decode_entities( $text->{confirm_subject} );
        $mail_body = decode_entities($mail_body);
        delete $ENV{PATH};
        open MAIL, "| $sendmail -oi -t";
        print MAIL <<EOF;
To: $email_addy
From: "$ini_name" <$ini_email>
Subject: $subject

$mail_body
EOF
        close MAIL;
    }
}

1;

# vim: set et ts=4 sw=4 ft=perl:
