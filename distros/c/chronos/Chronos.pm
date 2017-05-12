# $Id: Chronos.pm,v 1.8 2002/09/17 00:20:17 nomis80 Exp $
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
package Chronos;

use strict;
use Chronos::Static qw(to_date from_date from_time Compare_YMD);
use Apache::DBI;
use Apache::Constants qw(:response);
use Date::Calc qw(:all);
use Chronos::Action::Showday;
use Chronos::Action::EditEvent;
use Chronos::Action::SaveEvent;
use Apache::Request;
use Chronos::Action::Showmonth;
use Chronos::Action::Showweek;
use Chronos::Action::EditTask;
use Chronos::Action::SaveTask;
use Chronos::Action::UserPrefs;
use Chronos::Action::SaveUserPrefs;
use Chronos::Action::GetFile;
use Chronos::Action::DelFile;
use HTML::Entities;
use POSIX qw(strftime);

our $VERSION = "1.1.6";
sub VERSION { $VERSION }

sub handler {
    my $r       = shift;
    my $chronos = Chronos->new($r);

    # Bon, ça fait deux heures que je gosse sur une requête POST qui marchait
    # pas et je viens de découvrir quelque chose de vraiment mongol. Voici une
    # petite quote de "man Apache":
    #
    #     $r->content
    #         The $r->content method will return the entity body read from the
    #         client, but only if the request content type is "applica-
    #         tion/x-www-form-urlencoded".  When called in a scalar context,
    #         the entire string is returned.  When called in a list context, a
    #         list of parsed key => value pairs are returned.  *NOTE*: you can
    #         only ask for this once, as the entire body is read from the
    #         client.
    #
    # La petite note à la fin fait toute la différence. Si je donne des
    # paramètres en POST, ils vont être "oubliés" rendu ici parce que
    # Chronos::Authz doit savoir quel type d'action on essait de faire pour
    # pouvoir autoriser ou non. C'est pour ça qu'on doit checker pour
    # l'autorisation ici et non dans un module à part.

    # Each action has its own authorization (not authentication) mechanism based
    # on the user's privileges.
    if ( $chronos->action->authorized ) {
        return $chronos->go;
    } else {
        # We are not authorized, print a nice error message in the logs
        # The user is the real username that has been entered in the login
        # dialog box.
        my $user   = $chronos->user;
        my $action = $chronos->{r}->param('action');
        # The object is the user on which $user is acting. Usually $object eq
        # $user, but a $user can act on a different $object if that $user has
        # enough privileges.
        my $object = $chronos->{r}->param('object');
        $r->note_basic_auth_failure;
        $r->log_reason(
            "user $user: not authorized (action: $action, object: $object)");
        return AUTH_REQUIRED;
    }
}

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;
    # We use Apache::Request for it's easy CGI request parsing. It is accessible
    # in the 'r' member of a Chronos object.
    my $r     = Apache::Request->new(shift);
    return bless { r => $r }, $class;
}

# This is sort of the main function. At this point, we are authorized. The goal
# is to execute the requested action and send the results back to the user. Some
# side-effects (like sending confirmation email) can happen too.
sub go {
    my $self = shift;

    # The language is stored in each user's properties as a two-letter code.
    my $lang = $self->lang;
    # We pass the two letter code to Date::Calc so that it switches language.
    # There might be a problem here with a race condition if two users of
    # different languages try to access Chronos at the same time. I still
    # haven't witnessed it, so it might not be a race condition after all.
    Language( Decode_Language($lang) );
    # This is set so that date & time formats passed to POSIX::strftime() get
    # localized. Again, maybe a race condition, maybe not.
    $ENV{LC_TIME} = $lang;

    # There are many types of actions. An action advertises its type by use of
    # the redirect() function or the freeform() function.
    if ( $self->action->redirect ) {
        # A redirect action sends its own content to the user along with a
        # Location: header.
        $self->action->content;
        # Our task is now to send the REDIRECT code so that the action's
        # Location: header takes effect.
        return REDIRECT;
    } elsif ( $self->action->freeform ) {
        # A freeform action can do anything. We just call its execute() method
        # and let it go.
        return $self->action->execute;
    } else {
        # A normal action fits in a predefined mold.
        # A standard header is printed.
        $self->header;
        # Then the body, which can be pretty much anything.
        $self->body;
        # A standard footer.
        $self->footer;
        # Then we send the page. The action does not send the page itself.
        $self->sendpage;
        return OK;
    }
}

# This function returns the two-letter language code of the passed username. The
# default is English, even though the language should always be defined.
sub lang {
    my $self        = shift;
    my $dbh         = $self->dbh;
    my $user_quoted = $dbh->quote( $self->user );
    my $lang        =
      $dbh->selectrow_array("SELECT lang FROM user WHERE user = $user_quoted")
      || 'en';
    return $lang;
}

# This function prints a standard header.
sub header {
    my $self = shift;

    my $object = $self->action->object;
    my $user   = $self->user;
    my $text   = $self->gettext;
    my $dbh    = $self->dbh;
    my $uri    = $self->{r}->uri;

    my ( $year, $month, $day ) = $self->day;

    # If the user is viewing today's showday, refresh every hour. When the user
    # leaves for the night, he'll come back in the morning with a showday
    # automagically showing tomorrow! (or today, whatever)
    my @today = Today();
    if (    $self->{r}->param('action') eq 'showday'
        and $today[0] == $year
        and $today[1] == $month
        and $today[2] == $day )
    {
        $self->{r}->header_out( 'Refresh',
            "3600;url=$uri?action=showday&object=$object" );
    }

    # That's the standard header. Note the use of Chronos::stylesheet() and
    # Chronos::javascript().
    $self->{page} .= <<EOF;
<html>
<head>
    <title>Chronos $VERSION: $object</title>
    <link rel="stylesheet" href="@{[$self->stylesheet]}" type="text/css">
    <script type="text/javascript">
@{[$self->javascript]}
    </script>
</head>

<body>
<table width="100%">
    <tr><td>
        <table width="100%" cellspacing=0>
            <tr>
                <td class=top>Chronos $VERSION - <a class=header href="$uri?action=userprefs">$user <img src="/chronos_static/home.png" border=0></a></td>
                <td class=top align=right><select name="object" style="background-color:black; color:white" onChange="switchobject(this.value)">
EOF

    # We next print a select widget in the top right corner that lets the user
    # change the object to another one. We only show objects on which the user
    # has at least read access.
    my $user_quoted = $dbh->quote( $self->user );
    # There are two ways to have privileges on an object. An object can be
    # declared public to everyone by using the public_readable and
    # public_writable columns in the user table. An object can refine the
    # privileges it gives to others by using the acl table, which works
    # individually for each user.
    my $from_user   =
      $dbh->selectall_arrayref(
"SELECT user, name, email FROM user WHERE user = $user_quoted OR public_readable = 'Y' OR public_writable = 'Y' ORDER BY name, user"
      );
    my $from_acl =
      $dbh->selectall_arrayref(
"SELECT user.user, user.name, user.email FROM user, acl WHERE acl.object = user.user AND acl.user = $user_quoted AND (acl.can_read = 'Y' OR acl.can_write = 'Y')"
      );
    my %users = map { $_->[0] => [ $_->[1], $_->[2] ] } @$from_user, @$from_acl;
    foreach (
        sort { $users{$a}[0] cmp $users{$b}[0] || $a cmp $b }
        keys %users
      )
    {
        my $string =
          ( $users{$_}[0] || $_ )
          . ( $users{$_}[1] ? " &lt;" . $users{$_}[1] . "&gt;" : '' );
        my $selected = $self->action->object eq $_ ? 'selected' : '';
        $self->{page} .= <<EOF;
        <option value="$_" $selected>$string</option>
EOF
    }

    # Here we insert the action-specific header.
    $self->{page} .= <<EOF;
                </select></td>
            </tr>
        </table>
    </td><tr><td>
<!-- Begin @{[ref $self->action]} header -->
@{[$self->action->header]}
<!-- End @{[ref $self->action]} header -->
    </td></tr>
    <tr>
        <td>
EOF
}

# This function simply calls the Chronos::Action::content() function of the
# action. Usually an action will be derived from the top Chronos::Action class,
# so content() will be different for each action.
sub body {
    my $self = shift;
    $self->{page} .= <<EOF;
<!-- Begin @{[ref $self->action]} body -->
@{[$self->action->content]}
<!-- End @{[ref $self->action]} body -->
EOF
}

# This function prints a standard footer. For the moment it only closes tags and
# does not call an action-specific function. If there is ever a need for
# action-specific footers, this is where we have to call the action-specific
# footer function.
sub footer {
    my $self = shift;
    $self->{page} .= <<EOF;
        </td>
    </tr>
</table>
</body>
EOF
}

# This returns the username that has been entered in the login box.
sub user {
    my $self = shift;
    return $self->{r}->connection->user;
}

# This is a fancy way of accessing the value of the configuration directive
# STYLESHEET.
sub stylesheet {
    my $self = shift;
    return $self->conf->{STYLESHEET};
}

# This prints javascript code that can be used further down the page.
sub javascript {
    my $self = shift;
    my ( $year, $month, $day ) = $self->day;
    my $uri    = $self->{r}->uri;
    my $action = $self->{r}->param('action');
    # A function that redirects the browser when the select in the top right
    # corner gets activated.
    return <<EOF
function switchobject(object) {
    window.location = ("$uri?object=" + object + "@{[$action ? "&action=$action" : '']}&year=$year&month=$month&day=$day");
}
EOF
}

# Send the page contained in the page property. All other functions simply put
# text in that property and it gets sent in one chunk at the end. I think this
# may be faster than printing a small chunk at a time, even if it may increase
# latency slightly.
sub sendpage {
    my $self = shift;
    $self->{r}->content_type('text/html');
    $self->{r}->send_http_header;
    $self->{r}->print( $self->{page} );
}

# Return the parsed config file as a hash reference.
sub conf {
    my $self = shift;
    # Cache the configuration so that we read the config file only one time per
    # request. We could cache it more, but I want it like this so that the
    # changes in the config file get applied immediatly, without needing a
    # restart of Apache.
    if ( not $self->{conf} ) {
        my $file = $self->{r}->dir_config("ChronosConfig");
        $self->{conf} = Chronos::Static::conf($file);
    }
    return $self->{conf};
}

# This function returns the database handle. It gets all its values from the
# configuration file. Apache::DBI caches the database handles.
sub dbh {
    my $self = shift;
    my $conf = $self->conf();
    my $dsn  =
      "dbi:$conf->{DB_TYPE}:$conf->{DB_NAME}"
      . ( $conf->{DB_HOST} ? ":$conf->{DB_HOST}" : '' )
      . ( $conf->{DB_PORT} ? ":$conf->{DB_PORT}" : '' );
    # Note the "RaiseError => 1". This means that any database error will cause
    # an internal server error and print a message in the logs. There should be
    # no error.
    my $dbh =
      DBI->connect( $dsn, $conf->{DB_USER}, $conf->{DB_PASS},
        { RaiseError => 1, PrintError => 0 } );
    return $dbh;
}

# This function returns a hash reference containing the language-specific
# strings from a file in /usr/share/chronos/lang/...
sub gettext {
    my $self = shift;
    # This hash is also cached so that we scan the language file only once per
    # request. Same rationale as for Chronos::conf().
    if ( not $self->{text} ) {
        $self->{text} = Chronos::Static::gettext( $self->lang );
    }
    return $self->{text};
}

# This function returns the action object based on the action the user has
# requested in its CGI query.
sub action {
    my $self = shift;
    my $action = shift;
    my $conf = $self->conf();

    # There are two ways to specify an action.
    if ( my $name = $self->{r}->param('action') ) {
        # Either you specify a CGI parameter named action...
        $action = $name;
    } elsif ( my $path_info = $self->{r}->path_info ) {
        # ...or you add the wanted action to the path info. This is used for
        # example in file attachment downloads, so that the browser names the
        # file correctly.
        ($action) = $path_info =~ /^\/([^\/]+)/;
    }

    # The default action is configureable, so you may want Chronos to start with
    # week or month view, for example.
    $action ||= $conf->{DEFAULT_ACTION};

    # This is a big switch statement.
    if ( $action eq 'showday' ) {
        return Chronos::Action::Showday->new($self);
    } elsif ( $action eq 'saveevent' ) {
        return Chronos::Action::SaveEvent->new($self);
    } elsif ( $action eq 'editevent' ) {
        return Chronos::Action::EditEvent->new($self);
    } elsif ( $action eq 'showmonth' ) {
        return Chronos::Action::Showmonth->new($self);
    } elsif ( $action eq 'showweek' ) {
        return Chronos::Action::Showweek->new($self);
    } elsif ( $action eq 'edittask' ) {
        return Chronos::Action::EditTask->new($self);
    } elsif ( $action eq 'savetask' ) {
        return Chronos::Action::SaveTask->new($self);
    } elsif ( $action eq 'userprefs' ) {
        return Chronos::Action::UserPrefs->new($self);
    } elsif ( $action eq 'saveuserprefs' ) {
        return Chronos::Action::SaveUserPrefs->new($self);
    } elsif ( $action eq 'getfile' ) {
        return Chronos::Action::GetFile->new($self);
    } elsif ( $action eq 'delfile' ) {
        return Chronos::Action::DelFile->new($self);
    }

    # If the $action parameter was not known, we end up here. We then call
    # ourself back with the default action as the parameter, to force a return
    # of the default action. A Chronos::Action object should never be used.
    # Chronos::Action should be considered a pure virtual.
    return $self->action($conf->{DEFAULT_ACTION});
}

# This function returns the $year,$month,$day values that should be used for
# display.
sub day {
    my $self  = shift;
    my $year  = $self->{r}->param('year');
    my $month = $self->{r}->param('month');
    my $day   = $self->{r}->param('day');
    # The defaults are today's date.
    my @today = Today();
    $year  ||= $today[0];
    $month ||= $today[1];
    $day   ||= $today[2];
    return ( $year, $month, $day );
}

# This function is the same as Chronos::day() except that it also returns a
# $hour variable.
sub dayhour {
    my $self = shift;
    my ( $year, $month, $day ) = $self->day;
    my $hour = $self->{r}->param('hour');
    # The default hour is now's hour.
    $hour = ( Now() )[0] if not defined $hour;
    return ( $year, $month, $day, $hour );
}

# I don't remember writing this function. It looks like it could be used to
# build a cache of events keyed by eid, but this is a bad concept. We don't need
# a cache of events, we have the DB instead and should let it do its work. I
# don't think any action calls it.
sub event {
    my $self = shift;
    my $eid  = shift;
    $self->{events} ||= {};
    if ( not $self->{events}{$eid} ) {
        $self->{events}{$eid} =
          $self->dbh->selectrow_hashref(
            "SELECT * FROM events WHERE eventid = $eid");
    }
    return $self->{events}{$eid};
}

# This is a function that should go into Chronos::Action, but I'm too lazy to
# move it. It works wonderfully that way, so why bother. It returns an HTML
# string representing the minimonth box displayed at the top left corner in the
# day view and the bottom right corner in the week view.
sub minimonth {
    my $self   = shift;
    my $object = $self->action->object;
    my $uri    = $self->{r}->uri;
    # $year, $month, and $day are the arguments to this function.
    my ( $year, $month, $day ) = @_;
    # If $day isn't specified or is 0, it means that we shouldn't highlight the
    # current day.
    my $nocur = !$day;
    # We then set $day to 1 because Date::Calc won't accept a $day of 0.
    $day ||= 1;

    # Do some calculations for the links displayed beside the month title. Get
    # the $year, $month, $day values for the next year, next month, previous
    # year, and previous month. We can be sure that Date::Calc will return
    # existing values. For example, we'll never end up with February 30th.
    my ( $prev_year, $prev_month, $prev_day ) =
      Add_Delta_YM( $year, $month, $day, 0, -1 );
    my ( $next_year, $next_month, $next_day ) =
      Add_Delta_YM( $year, $month, $day, 0, 1 );
    my ( $prev_prev_year, $prev_prev_month, $prev_prev_day ) =
      Add_Delta_YM( $year, $month, $day, -1, 0 );
    my ( $next_next_year, $next_next_month, $next_next_day ) =
      Add_Delta_YM( $year, $month, $day, 1, 0 );

    # Print the month header. This looks like
    #       << < January > >>
    # The double arrows go back/forward one year while the single arrows go
    # back/forward one month.
    # The HTML is all on one line so that it doesn't get separated and look like
    # this:
    #       << < January >
    #             >>
    my $return = <<EOF;
<!-- Begin Chronos::minimonth -->
<table class=minimonth>
    <tr>
        <th class=minimonth colspan=7><a class=minimonthheader href="$uri?action=showday&amp;object=$object&amp;year=$prev_prev_year&amp;month=$prev_prev_month&amp;day=$prev_prev_day"><img src="/chronos_static/back2.png" border=0></a>&nbsp;<a class=minimonthheader href="$uri?action=showday&amp;object=$object&amp;year=$prev_year&amp;month=$prev_month&amp;day=$prev_day"><img src="/chronos_static/back.png" border=0></a>&nbsp;<a class=minimonthheader href="$uri?action=showmonth&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day">@{[ucfirst Month_to_Text($month)]}</a>&nbsp;$year&nbsp;<a class=minimonthheader href="$uri?action=showday&amp;object=$object&amp;year=$next_year&amp;month=$next_month&amp;day=$next_day"><img src="/chronos_static/forward.png" border=0></a>&nbsp;<a class=minimonthheader href="$uri?action=showday&amp;object=$object&amp;year=$next_next_year&amp;month=$next_next_month&amp;day=$next_next_day"><img src="/chronos_static/forward2.png" border=0></a></th>
    </tr>
    <tr>
EOF

    # Dans Date::Calc, toutes les fonctions utilisent 1 pour lundi et 7 pour
    # dimanche. C'est pourquoi le minimonth commence à partir de lundi et non
    # dimanche comme on pourrait s'y attendre. Voici ce que l'auteur de
    # Date::Calc dit pour justifier ce choix:
    #
    #     Note that in the Hebrew calendar (on which the Christian calendar
    #     is based), the week starts with Sunday and ends with the Sabbath
    #     or Saturday (where according to the Genesis (as described in the
    #     Bible) the Lord rested from creating the world).
    # 
    #     In medieval times, catholic popes have decreed the Sunday to be
    #     the official day of rest, in order to dissociate the Christian
    #     from the Hebrew belief.
    # 
    #     Nowadays, the Sunday AND the Saturday are commonly considered (and
    #     used as) days of rest, usually referred to as the "week-end".
    # 
    #     Consistent with this practice, current norms and standards (such
    #     as ISO/R 2015-1971, DIN 1355 and ISO 8601) define the Monday as
    #     the first day of the week.

    # Print another header with the day of week name abbreviations.
    foreach ( 1 .. 7 ) {
        $return .= <<EOF;
        <td>@{[encode_entities(Day_of_Week_Abbreviation($_))]}</td>
EOF
    }

    $return .= <<EOF;
    </tr>
EOF

    # Next is the algorithm that prints the days in the previous month but in
    # the same week as the 1st.
    my $dow_first = Day_of_Week( $year, $month, 1 );
    if ( $dow_first != 1 ) {
        $return .= <<EOF;
    <tr>
EOF
    }
    # Go from the nearest Monday up to one day before the 1st of this month, ie.
    # the last day of the previous month. These are shown differently from the
    # days of this month.
    foreach ( 1 .. ( $dow_first - 1 ) ) {
        my ( $mini_year, $mini_month, $mini_day ) =
          Add_Delta_Days( $year, $month, 1, -( $dow_first - $_ ) );
        $return .= <<EOF;
        <td><a class=dayothermonth href="$uri?action=showday&amp;object=$object&amp;year=$mini_year&amp;month=$mini_month&amp;day=$mini_day">$mini_day</a></td>
EOF
    }

    # Now print the current month's days.
    my $days = Days_in_Month( $year, $month );
    my ( $curyear, $curmonth, $curday ) = Today();
    foreach ( 1 .. $days ) {
        # Highlight the current day unless no $day had been passed to the
        # function.
        my $tdclass = "class=curday" if $_ == $day and not $nocur;
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
        $return .= <<EOF;
        <td $tdclass><a class=$class href="$uri?action=showday&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$_">$_</a></td>
EOF
        if ( $dow == 7 ) {
            $return .= <<EOF;
    </tr>
EOF
        }
    }

    # Then print the days which are on the same week as the last day of this
    # month but that are of the following month.
    my $dow_last = Day_of_Week( $year, $month, $days );
    foreach ( ( $dow_last + 1 ) .. 7 ) {
        my ( $mini_year, $mini_month, $mini_day ) =
          Add_Delta_Days( $year, $month, $days, ( $_ - $dow_last ) );
        $return .= <<EOF;
        <td><a class=dayothermonth href="$uri?action=showday&amp;object=$object&amp;year=$mini_year&amp;month=$mini_month&amp;day=$mini_day">$mini_day</a></td>
EOF
    }

    # As a footer, print a link to today's day, along with the date, nicely
    # formatted.
    my $text  = $self->gettext;
    my $today = $self->format_date( $self->conf->{MINIMONTH_DATE_FORMAT},
        $curyear, $curmonth, $curday, 0, 0, 0 );
    $return .= <<EOF;
    </tr>
    <tr>
        <td colspan=7 class=minimonthfooter>
            <a class=daycurmonth href="$uri?action=showday&amp;object=$object&amp;year=$curyear&amp;month=$curmonth&amp;day=$curday">$text->{today}</a>, $today
        </td>
    </tr>
</table>
<!-- End Chronos::minimonth -->
EOF

    return $return;
}

# This function is used in Showmonth and Showweek to find the events happening
# in a given day.
# This really should be transformed into a method of an object Chronos::Day. But
# what use would be an object with only one method? Feel free to implement
# Chronos::Day if you wish. 
sub events_per_day {
    my $self   = shift;
    my $view   = uc shift;                # 'month' or 'week'
    my $uri    = $self->{r}->uri;
    my $dbh    = $self->dbh;
    my $object = $self->action->object;
    my ( $year, $month, $day ) = @_;
    my $conf = $self->conf;

    my $sth_events = $dbh->prepare( <<EOF );
SELECT eid, name, start_date, start_time, end_date, end_time
FROM events
WHERE
    initiator = ?
    AND start_date <= ?
    AND end_date >= ?
ORDER BY start_date, start_time, name
EOF
    my $sth_participants = $dbh->prepare( <<EOF );
SELECT events.eid, events.name, events.start_date, events.start_time, events.end_date, events.end_time
FROM events, participants
WHERE
    events.eid = participants.eid
    AND participants.user = ?
    AND events.start_date <= ?
    AND events.end_date >= ?
ORDER BY events.start_date, events.start_time, events.name
EOF

    # The two statements above take as input:
    # 1) The current object
    # 2) Today's date
    # 3) Today's date

    my $today = to_date( $year, $month, $day );

    # Initialize the return value.
    my $return = "";
    # We have two queries that can return events: the events of which the user
    # is the initiator and the events of which the user is a participant.
    foreach my $sth ( $sth_events, $sth_participants ) {
        # Thankfully, both queries take the same parameters.
        $sth->execute( $object, $today, $today );
        while (
            my ( $eid, $name, $start_date, $start_time, $end_date, $end_time ) =
            $sth->fetchrow_array )
        {
            # We have one event selected, decompose it's start date and time...
            my ( $syear, $smonth, $sday, $shour, $smin, $ssec ) =
              ( from_date($start_date), from_time($start_time) );
            # ...and it's end date and time.
            my ( $eyear, $emonth, $eday, $ehour, $emin, $esec ) =
              ( from_date($end_date), from_time($end_time) );
            # We then have to print a nicely formatted range, ie. start - end
            my $range;
            if ( $syear == $year and $smonth == $month and $sday == $day ) {
                # The event starts today, we need a range
                my $format;
                if ( defined $start_time ) {
                    # The event has a time associated with it, ie. it doesn't
                    # take all day.
                    if (
                        Compare_YMD( $syear, $smonth, $sday, $eyear, $emonth,
                            $eday ) == 0
                      )
                    {
                        # The event lasts only this day, we can abbreviate the
                        # range info and not print the date.
                        $format = $conf->{"${view}_DATE_FORMAT"};
                    } else {
                        # The event spans multiple days.
                        $format = $conf->{"${view}_MULTIDAY_DATE_FORMAT"};
                    }
                } elsif (
                    # The event has no time associated with it, ie. it takes all
                    # day.
                    Compare_YMD( $syear, $smonth, $sday, $eyear, $emonth,
                        $eday ) != 0
                  )
                {
                    # The event spans multiple days.
                    $format = $conf->{"${view}_MULTIDAY_NOTIME_DATE_FORMAT"};
                } else {
                    # The event lasts only this day.
                    $format = $conf->{"${view}_NOTIME_DATE_FORMAT"};
                }
                # If we have a range, we format it so that we have "start -
                # end". Else the $format is an empty string.
                $range = $format
                  ? encode_entities(
                    sprintf '%s - %s ',
                    $self->format_date(
                        $format, $syear, $smonth, $sday,
                        $shour,  $smin,  $ssec
                    ),
                    $self->format_date(
                        $format, $eyear, $emonth, $eday,
                        $ehour,  $emin,  $esec
                    )
                  )
                  : '';
            } else {
                # The events started another day and continues today. Print
                # no range.
            }

            # Print the event link preceded by a nice bullet.
            $return .= <<EOF;
            <br>&bull; $range<a class=event href="$uri?action=editevent&amp;eid=$eid&amp;object=$object&amp;year=$year&amp;month=$month&amp;day=$day">$name</a>
EOF
        }
        $sth->finish;
    }
    return $return;
}

# This function formats a date according to a format string. The first argument
# is the format string, which is a modified POSIX::strftime() format. See
# strftime(3). Two additional tokens get interpolated: %(long) will be replaced
# by a call to Date::Calc::Date_to_Text_Long() and %(short) will be replaced by
# a call to Date::Calc::Date_to_Text().
# The other arguments specify a time, either in the Date::Calc format, which is
# an array of 6 elements ($year,$month,$day,$hour,$min,$sec) that represent
# naturally a moment, or an array of 9 elements as returned by the localtime()
# function. See 'perldoc localtime' for its special format.
sub format_date {
    my $self   = shift;
    my $format = shift;
    my ( @calc_time, @localtime );
    # Depending on the format we have, we need to convert one to the other
    # because Date_to_Text* functions take a Date::Calc format while strftime()
    # takes a localtime() format.
    if ( @_ == 9 ) {
        @localtime = @_;
        @calc_time = ( $_[5] + 1900, $_[4] + 1, @_[ 3 .. 0 ] );
    } elsif ( @_ == 6 ) {
        @calc_time = @_;
        @localtime = localtime( Mktime(@_) );
    } else {
        die
'Usage: format_date(@localtime) or format_date($year, $month, $day, $hour, $min, $sec)';
    }

    # Compute the $long and $short substitution texts.
    my $long  = Date_to_Text_Long( @calc_time[ 0 .. 2 ] );
    my $short = Date_to_Text( @calc_time[ 0 .. 2 ] );
    # Substitute them.
    $format =~ s/\%\(long\)/$long/;
    $format =~ s/\%\(short\)/$short/;
    # Now pass everything to strftime(), hoping nothing will go wrong. Return
    # what strftime() returns.
    return strftime( $format, @localtime );
}

1;
# vim: set et ts=4 sw=4:
