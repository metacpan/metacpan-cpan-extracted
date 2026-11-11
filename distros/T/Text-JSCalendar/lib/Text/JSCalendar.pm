#/usr/bin/perl -cw
use strict;
use warnings;
package Text::JSCalendar;

use Carp;
use Data::ICal;
use Data::ICal::Entry::Event;
use Data::ICal::TimeZone;
use Data::ICal::Entry::Alarm::Email;
use Data::ICal::Entry::Alarm::Display;
use DateTime::Format::ICal;
use DateTime::TimeZone;
use JSON::XS qw(encode_json);
use Text::JSCalendar::TimeZones;
use Text::VCardFast qw(vcard2hash);
use MIME::Base64 qw(encode_base64);
use MIME::Types;
use Digest::SHA qw(sha1_hex);
use Data::Dumper;
use JSON;

use Text::JSCalendar::TimeZones;

# monkey patch like a bandit
BEGIN {
  my @alarm_properties = Data::ICal::Entry::Alarm::optional_unique_properties();
  foreach my $want (qw(uid acknowledged)) {
    push @alarm_properties, $want unless grep { $_ eq $want } @alarm_properties;
  }
  no warnings 'redefine';
  *Data::ICal::Entry::Alarm::optional_unique_properties = sub { @alarm_properties };
}

our $UTC = DateTime::TimeZone::UTC->new();
our $FLOATING = DateTime::TimeZone::Floating->new();
our $LOCALE = DateTime::Locale->load('en_US');

# MIME::Types->new is slow; made once, when an ATTACH first needs it
my $MimeTypes;

# The vendor-specific property (jscalendarbis-22 1.8.1) that marks a
# master the reader made up; see "Synthetic masters" in the POD.
use constant SYNTHETIC_MASTER => 'jscalendar.fastmail.com:syntheticMaster';

my (
  %ValidDay,
  %ValidFrequency,
  %EventKeys,
  %ColorNames,
  %RecurrenceProperties,
  %UTCLinks,
  %MustBeTopLevel,
  %OrganizerOnly,
);

BEGIN {
  %ValidDay = map { $_ => 1 } qw(su mo tu we th fr sa);
  %ValidFrequency = map { $_ => 1 } qw(yearly monthly weekly daily hourly minutely secondly);

  # Property name => [container, type, required, default], per object
  # type (the key "" is the Event or Task itself).  container is 0 for a
  # single value, 1 for an array, 2 for an Id- or String-keyed map; type
  # "object" recurses into the table of the same name and "patch" into
  # a PatchObject.  Defaults are jscalendarbis-22 (or RFC 8984 for the
  # properties -22 reserved); only NormaliseEvent reads this table.
  %EventKeys = (
    '' => {
      uid                  => [0, 'string',    1, undef],
      relatedTo            => [2, 'object',    0, undef],
      keywords             => [0, 'keywords',  0, undef],
      categories           => [0, 'keywords',  0, undef],
      prodId               => [0, 'string',    0, undef],
      created              => [0, 'utcdate',   0, undef],
      updated              => [0, 'utcdate',   1, undef],
      sequence             => [0, 'number',    0, 0],
      method               => [0, 'string',    0, undef],
      title                => [0, 'string',    0, ''],
      description          => [0, 'string',    0, ''],
      descriptionContentType => [0, 'string',  0, "text/plain"],   # jscalendarbis-22 3.2.3
      links                => [2, 'object',    0, undef],
      locale               => [0, 'string',    0, undef],
      locations            => [2, 'object',    0, undef],
      virtualLocations     => [2, 'object',    0, undef],
      color                => [0, 'string',    0, undef],
      showWithoutTime      => [0, 'bool',      0, $JSON::false],
      start                => [0, 'localdate', 1, undef],
      timeZone             => [0, 'timezone',  0, undef],
      duration             => [0, 'duration',  0, "PT0S"],    # jscalendarbis-22 4.1.2
      recurrenceRule          => [0, 'object',    0, undef],
      recurrenceOverrides     => [2, 'patch',     0, undef],
      recurrenceId         => [0, 'localdate', 0, undef],
      recurrenceIdTimeZone => [0, 'timezone',  0, undef],
      status               => [0, 'string',    0, "confirmed"], # jscalendarbis-22 4.1.4
      freeBusyStatus       => [0, 'string',    0, 'busy'],
      privacy              => [0, 'string',    0, 'public'],
      priority             => [0, 'number',    0, 0],
      organizerCalendarAddress => [0, 'string',  0, undef],
      sentBy               => [0, 'string',    0, undef],
      endTimeZone          => [0, 'timezone',  0, undef],
      participants         => [2, 'object',    0, undef],
      alerts               => [2, 'object',    0, undef],
      version              => [0, 'string',    0, undef],
      # Task-specific properties
      due                  => [0, 'localdate', 0, undef],
      estimatedDuration    => [0, 'duration',  0, undef],
      percentComplete      => [0, 'number',    0, undef],
      progress             => [0, 'string',    0, undef],
    },
    links => {
      href                 => [0, 'string',    1, undef],
      contentType          => [0, 'string',    0, undef],
      size                 => [0, 'number',    0, undef],
      rel                  => [0, 'string',    0, 'enclosure'],   # jscalendarbis-22 1.5.11
      title                => [0, 'string',    0, undef],
      display              => [2, 'bool',      0, undef],
    },
    locations => {
      name                 => [0, 'string',    0, undef],
      coordinates          => [0, 'string',    0, undef],
      locationTypes        => [0, 'keywords',  0, undef],
      links                => [2, 'object',    0, undef],
    },
    virtualLocations => {
      name                 => [0, 'string',    0, ''],
      uri                  => [0, 'string',    1, undef],
      features             => [0, 'keywords',  0, undef],
    },
    recurrenceRule => {
      frequency            => [0, 'string',    1, undef],
      interval             => [0, 'number',    0, 1],         # jscalendarbis-22 3.3.3
      rscale               => [0, 'string',    0, 'gregorian'],
      skip                 => [0, 'string',    0, 'omit'],
      firstDayOfWeek       => [0, 'string',    0, 'mo'],
      byDay                => [1, 'object',    0, undef],
      byMonthDay           => [1, 'number',    0, undef],
      byMonth              => [1, 'string',    0, undef],
      byYearDay            => [1, 'number',    0, undef],
      byWeekNo             => [1, 'number',    0, undef],
      byHour               => [1, 'number',    0, undef],
      byMinute             => [1, 'number',    0, undef],
      bySecond             => [1, 'number',    0, undef],
      bySetPosition        => [1, 'number',    0, undef],
      count                => [0, 'number',    0, undef],
      until                => [0, 'localdate', 0, undef],
    },
    relatedTo => {
      relation             => [2, 'bool',      0, undef],
    },
    byDay => {
      day                  => [0, 'string',    1, undef],
      nthOfPeriod          => [0, 'number',    0, undef],
    },
    participants => {
      name                 => [0, 'string',    1, undef],
      email                => [0, 'string',    1, undef],
      calendarAddress      => [0, 'string',    0, undef],
      kind                 => [0, 'string',    0, undef],     # no default (jscalendarbis-22 3.4.6)
      roles                => [2, 'bool',      1, undef],
      locationId           => [0, 'string',    0, undef],
      participationStatus  => [0, 'string',    0, 'needs-action'],
      expectReply          => [0, 'bool',      0, $JSON::false],
      scheduleAgent        => [0, 'string',    0, "server"],    # RFC 8984 4.4.6
      scheduleSequence     => [0, 'number',    0, 0],
      scheduleUpdated      => [0, 'utcdate',   0, undef],
      scheduleStatus       => [1, 'string',    0, undef],
      participationComment => [0, 'string',    0, undef],
      invitedBy            => [0, 'string',    0, undef],
      memberOf             => [2, 'bool',      0, undef],
      sentBy               => [0, 'string',    0, undef],
      progress             => [0, 'string',    0, undef],
      progressUpdated      => [0, 'utcdate',   0, undef],
      delegatedFrom        => [0, 'keywords',  0, undef],
      delegatedTo          => [0, 'keywords',  0, undef],
      description          => [0, 'string',    0, undef],
      descriptionContentType => [0, 'string',  0, undef],
      links                => [2, 'object',    0, undef],
    },
    alerts => {
      trigger              => [0, 'object',    1, undef],
      acknowledged         => [0, 'string',    0, undef],
      action               => [0, 'string',    0, 'display'],
    },
    # the Alert trigger: an OffsetTrigger when @type is unset or
    # "OffsetTrigger" (its defaultType, jscalendarbis-22 3.5.1); any other
    # @type is kept as it is
    trigger => {
      offset               => [0, 'string',    1, undef],
      relativeTo           => [0, 'string',    0, 'start'],
    },
  );

  %RecurrenceProperties = (
    bymonthday => {
      name   => 'byMonthDay',
      max    => 31,
      signed => 1,
    },
    byyearday  => {
      name   => 'byYearDay',
      max    => 366,
      signed => 1,
    },
    byweekno   => {
      name   => 'byWeekNo',
      max    => 53,
      signed => 1,
    },
    byhour     => {
      name => 'byHour',
      max  => 23,
    },
    byminute   => {
      name => 'byMinute',
      max  => 59,
    },
    bysecond   => {
      name => 'bySecond',
      max  => 60,
    },
    bysetpos   => {
      name   => 'bySetPosition',
      max    => 366,
      signed => 1,
    },
  );

  %MustBeTopLevel = map { $_ => 1 } SYNTHETIC_MASTER, qw{
    @type
    uid
    prodId
    showWithoutTime
    recurrenceRule
    recurrenceOverrides
    organizerCalendarAddress
    method
    privacy
    sentBy
    recurrenceId
    recurrenceIdTimeZone
  };

  # Participant properties that convert to ORGANIZER parameters
  %OrganizerOnly = map { $_ => 1 } qw{
    @type
    calendarAddress
    email
    name
    roles
    sentBy
  };

  # Color names defined in CSS Color Module Level 3
  # http://www.w3.org/TR/css3-color/

  %ColorNames
    = map { $_ => 1 }
      qw{
        aliceblue
        antiquewhite
        aqua
        aquamarine
        azure
        beige
        bisque
        black
        blanchedalmond
        blue
        blueviolet
        brown
        burlywood
        cadetblue
        chartreuse
        chocolate
        coral
        cornflowerblue
        cornsilk
        crimson
        cyan
        darkblue
        darkcyan
        darkgoldenrod
        darkgray
        darkgreen
        darkgrey
        darkkhaki
        darkmagenta
        darkolivegreen
        darkorange
        darkorchid
        darkred
        darksalmon
        darkseagreen
        darkslateblue
        darkslategray
        darkslategrey
        darkturquoise
        darkviolet
        deeppink
        deepskyblue
        dimgray
        dimgrey
        dodgerblue
        firebrick
        floralwhite
        forestgreen
        fuchsia
        gainsboro
        ghostwhite
        gold
        goldenrod
        gray
        green
        greenyellow
        grey
        honeydew
        hotpink
        indianred
        indigo
        ivory
        khaki
        lavender
        lavenderblush
        lawngreen
        lemonchiffon
        lightblue
        lightcoral
        lightcyan
        lightgoldenrodyellow
        lightgray
        lightgreen
        lightgrey
        lightpink
        lightsalmon
        lightseagreen
        lightskyblue
        lightslategray
        lightslategrey
        lightsteelblue
        lightyellow
        lime
        limegreen
        linen
        magenta
        maroon
        mediumaquamarine
        mediumblue
        mediumorchid
        mediumpurple
        mediumseagreen
        mediumslateblue
        mediumspringgreen
        mediumturquoise
        mediumvioletred
        midnightblue
        mintcream
        mistyrose
        moccasin
        navajowhite
        navy
        oldlace
        olive
        olivedrab
        orange
        orangered
        orchid
        palegoldenrod
        palegreen
        paleturquoise
        palevioletred
        papayawhip
        peachpuff
        peru
        pink
        plum
        powderblue
        purple
        red
        rosybrown
        royalblue
        saddlebrown
        salmon
        sandybrown
        seagreen
        seashell
        sienna
        silver
        skyblue
        slateblue
        slategray
        slategrey
        snow
        springgreen
        steelblue
        tan
        teal
        thistle
        tomato
        turquoise
        violet
        wheat
        white
        whitesmoke
        yellow
        yellowgreen
      };

  %UTCLinks = (
    'Etc/GMT-0'     => 1,
    'Etc/GMT+0'     => 1,
    'Etc/GMT0'      => 1,
    'Etc/GMT'       => 1,
    'Etc/Greenwich' => 1,
    'Etc/UCT'       => 1,
    'Etc/Universal' => 1,
    'Etc/UTC'       => 1,
    'Etc/Zulu'      => 1,
    'GMT'           => 1,
    'UCT'           => 1,
    'UTC'           => 1,
  );
}


=head1 NAME

Text::JSCalendar - convert between iCalendar and JSCalendar

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

This module implements a perl mapping between iCalendar:

    https://tools.ietf.org/html/rfc5545

and JSCalendar:

    https://datatracker.ietf.org/doc/draft-ietf-calext-jscalendar/

=head1 SUBROUTINES/METHODS

=cut

sub new {
  my $class = shift;
  return bless {@_}, ref($class) || $class;
}

=head2 Synthetic masters

An iCalendar object may hold only some instances of a recurring event
(RECURRENCE-ID components without their master, as a CalDAV server
gives an attendee invited to one occurrence: jscalendar-icalendar-29
calls them stand-alone recurrence instances).  C<vcalendarToEvents>
returns a single object per UID, so it makes up a master for them: its
C<start>, C<timeZone>, C<updated> and the properties an override may not
change come from the first instance, and every instance is one of its
C<recurrenceOverrides> (even one that patches nothing).

Such a master is marked with the vendor-specific property

    "jscalendar.fastmail.com:syntheticMaster": true

(jscalendarbis-22 1.8.1, so it cannot collide with a JSCalendar
property, and JSCalendar implementations must preserve it).  The name is
the constant C<Text::JSCalendar::SYNTHETIC_MASTER>.  It is in the object
rather than beside it so that it survives being stored and read back
before the object is written again.

C<eventsToVCalendar> writes only the instances of a marked master, each
as a RECURRENCE-ID component (an excluded one is not written), and never
a component for the master itself.  Every other object is written whole.
To turn a synthetic master into a real one, delete the property.
C<occurrences> of a synthetic master are its override keys, and
C<instance> gives the instance with the property removed.

=head2 Text::JSCalendar->isSyntheticMaster($Event)

True if C<$Event> is a master made up by the reader (see above).  May
also be called on an object or as a function.

=cut

sub isSyntheticMaster {
  my $Event = pop;
  return 0 unless ref $Event eq 'HASH';
  return $Event->{SYNTHETIC_MASTER()} ? 1 : 0;
}

=head2 $self->errors()

What the last call to C<vcalendarToEvents> or C<eventsToVCalendar> (or
C<_argsToVCalendar>) had to drop.  Neither dies because one component
is bad: an iCalendar VEVENT or VTODO, VALARM or RRULE that cannot be
converted is left out of the result, and so is a JSCalendar object or
alert that cannot be written.  The rest of the calendar converts as
usual.

Returns a list of hashes, empty when nothing was dropped:

    {
      uid       => 'abc@example.com', # the object's UID (undef if it had none)
      component => 'RRULE',           # what was dropped: VEVENT, VTODO,
                                      # VALARM, RRULE (reading), or
                                      # Event, Task, Alert (writing)
      id        => 'alarm-1',         # the alarm or alert id, if known
      message   => 'Invalid recurrence FREQ (fortnightly)',
    }

The list is reset at the start of each of those calls, and so is
C<warnings>.

=cut

sub errors {
  my $Self = shift;
  return @{$Self->{_errors} || []};
}

=head2 $self->warnings()

What the last call to C<vcalendarToEvents> or C<eventsToVCalendar> (or
C<_argsToVCalendar>) found odd but converted anyway: an iCalendar
component with both DTEND and DURATION, a second component of one UID
without RECURRENCE-ID, a property Data::ICal says is missing.  The same
shape as C<errors>, and reset with it.  The module never writes these to
STDERR.

=cut

sub warnings {
  my $Self = shift;
  return @{$Self->{_warnings} || []};
}

sub _warning {
  my ($Self, $uid, $component, $msg) = @_;
  push @{$Self->{_warnings}}, {
    uid => $uid,
    component => $component,
    message => $msg,
  };
}

sub _resetDiagnostics {
  my $Self = shift;
  $Self->{_errors} = [];
  $Self->{_warnings} = [];
}

# Run $code with Data::ICal's carps caught: it warns about every property
# it does not know (COLOR, CONFERENCE, ...: most of what this module
# writes) and about missing mandatory ones.  The first are expected; the
# second become warnings().  Any other warning goes on to the caller's
# handler.  (This used to be a $SIG{__WARN__} replaced for the whole
# process when the module was loaded.)
sub _withICalWarnings {
  my ($Self, $code) = @_;
  my $outer = $SIG{__WARN__};
  local $SIG{__WARN__} = sub {
    my $msg = $_[0];
    return if $msg =~ /^Unknown property for Data::ICal::Entry::/;
    if ($msg =~ /^Mandatory property for (Data::ICal::\S+) missing: (\S+)/) {
      $Self->_warning(undef, $1, "missing mandatory property $2");
      return;
    }
    if (ref $outer eq 'CODE') { $outer->(@_) }
    else { warn @_ }
  };
  return $code->();
}

# Report a dropped component.  $msg is a die message: only its first
# line is kept, without Carp's location.
sub _error {
  my ($Self, $uid, $component, $msg, $id) = @_;
  $msg = defined $msg ? "$msg" : '';
  $msg =~ s/\n.*//s;
  $msg =~ s/ at \S+ line \d+\.?$//;
  $msg = 'unknown error' unless length $msg;
  push @{$Self->{_errors}}, {
    uid => $uid,
    component => $component,
    defined $id ? (id => $id) : (),
    message => $msg,
  };
}

=head2 $self->tz($name)

Returns a DateTime::TimeZone object for the given name, but caches
the result for speed.

=cut

sub tz {
  my $Self = shift;
  my $tzName = shift;
  return $FLOATING unless defined $tzName;
  return $UTC if $UTCLinks{$tzName};
  unless (exists $Self->{_tz}{$tzName}) {
    $Self->{_tz}{$tzName} = DateTime::TimeZone->new(name => $tzName);
  }
  return $Self->{_tz}{$tzName};
}

sub color {
  my $Self = shift;
  my $color = shift;
  return _fixColor($color);
}

sub _fixColor {
  my $color = lc(shift || '');

  return $color if $ColorNames{$color};
  confess("unparseable color: $color") unless $color =~ m/^\s*(\#[a-f0-9]{3,8})\s*$/;
  $color = $1;
  return uc($color) if length($color) == 7;

  # Optional digit is for transparency (RGBA)
  if ( $color =~ m/^#(.)(.)(.).?$/ ) {
    return uc "#$1$1$2$2$3$3";
  }

  # Last two digits are for transparency (RGBA)
  if ( length($color) == 9 ) {
    return uc(substr($color,0,7));
  }

  confess("invalid color: $color");   # e.g. five or seven hex digits
}

sub _BYDAY2byDay {
  my ($BYDAY) = @_;

  my ($Count, $Day) = $BYDAY =~ /^([-+]?\d+)?(\w\w)$/;

  unless ($Day) {
    confess 'Recurrence BYDAY-weekday not specified';
  }

  unless ($ValidDay{lc $Day}) {
    confess 'Invalid recurrence BYDAY-weekday';
  }

  if ($Count) {
    unless (($Count >= -53) and ($Count <= 53)) {
      confess 'Recurrence BYDAY-ordwk is out of range';
    }
  }

  return {
    '@type' => 'NDay',
    day => lc $Day,
    $Count ? (nthOfPeriod => int($Count)) : (),
  };
}

sub _byDay2BYDAY {
  my ($byDay) = @_;

  unless (defined $byDay) {
    confess 'Invalid recurrence byDay';
  }

  unless (ref $byDay eq 'HASH') {
    confess 'Recurrence byDay is not an object';
  }

  my $Day = $byDay->{day};
  unless ($Day and $ValidDay{lc $Day}) {
    confess 'Recurrence byDay is not a known day';
  }

  my $Prefix = '';
  $Prefix = int($byDay->{nthOfPeriod}) if $byDay->{nthOfPeriod};

  return $Prefix . uc($Day);
}

sub _makeDateObj {
  my $Self = shift;
  my $DateStr = shift;
  my $TZStr = shift;
  my $TargetTz = shift;

  my ($Date, $HasTime) = _vDate($DateStr);

  # if it's all day, return it immediately
  return ($Date, 1) unless $HasTime;

  # Do the timezone manipulation as required
  $Date->set_time_zone($Self->tz($TZStr)) if $TZStr;
  $Date->set_time_zone($Self->tz($TargetTz)) if $TargetTz;

  return ($Date, 0);
}

sub _getDateObj {
  my $Self = shift;
  my $Calendar = shift;
  my $VItem = shift;
  my $TargetTz = shift;

  my $TimeZone = $Self->_getTimeZone($Calendar, $VItem);
  my ($Date, $IsAllDay) = $Self->_makeDateObj($VItem->{value}, $TimeZone, $TargetTz);

  return (wantarray ? ($Date, $TimeZone, $IsAllDay) : $Date);
}

sub _getDateObjMulti {
  my $Self = shift;
  my $Calendar = shift;
  my $VItem = shift;
  my $TargetTz = shift;

  my @Dates;

  my $TimeZone = $Self->_getTimeZone($Calendar, $VItem);
  foreach my $Value (split /,/, $VItem->{value}) {
    # XXX - handle $V2 sanely
    if (lc($VItem->{params}{value}[0] || '') eq 'period') {
      ($Value, my $V2) = split /\//, $Value;
    }
    my ($Date, $IsAllDay) = $Self->_makeDateObj($Value, $TimeZone, $TargetTz);
    push @Dates, $Date;
  }

  return @Dates;
}

# Exclude DTSTAMP from auto uid generation
sub _hexkey {
  my $VEvent = shift;
  my $extra = shift || '';
  my $updated = delete $VEvent->{properties}->{updated};
  my $d = Data::Dumper->new([$VEvent]);
  $d->Indent(0);
  $d->Sortkeys(1);
  my $Key = sha1_hex($d->Dump() . $extra);
  $VEvent->{properties}->{updated} = $updated if defined $updated;
  return $Key;
}

# An iCalendar INTEGER as a number, or undef if it is not one.
sub _intValue {
  my $value = shift;
  return undef unless defined $value and $value =~ /^\s*([-+]?\d+)\s*$/;
  return int $1;
}

sub _saneuid {
  my $uid = shift;
  return unless $uid;
  return if $uid =~ m/\s/;
  return if $uid =~ m/[\x7f-\xff]/;
  # any other sanity checks?
  return 1;
}

# The key the reader gives a participant whose ATTENDEE/ORGANIZER carries
# no JSID: a hash of its address.  The writer omits JSID when the key
# already matches this (jscalendar-icalendar 2.3.4, 2.3.29).
sub _defaultParticipantKey {
  my $uri = shift;
  return undef unless defined $uri;
  $uri =~ s/^mailto://i;
  return undef if $uri eq '';
  return sha1_hex(lc $uri);
}

# The JSID parameter (jscalendar-icalendar 4.2.1), or the older X-JMAP-ID,
# if it is a valid Id (jscalendarbis 1.4.1).
sub _propJSID {
  my $Prop = shift;
  for my $param (qw(jsid x-jmap-id)) {
    my $id = $Prop->{params}{$param} && $Prop->{params}{$param}[0];
    return $id if defined $id and $id =~ m/\A[A-Za-z0-9_-]{1,255}\z/;
  }
  return undef;
}

# (title => ...) from the first of the named parameters that is set.
sub _linkTitle {
  my ($Prop, @params) = @_;
  for my $param (@params) {
    my $v = $Prop->{params}{$param} && $Prop->{params}{$param}[0];
    return (title => $v) if defined $v && length $v;
  }
  return ();
}

# The SENT-BY parameter of an ATTENDEE or ORGANIZER as an email address
# (the "mailto:" dropped), or undef.
sub _mailto {
  my $addr = shift;
  return $addr =~ /^[A-Za-z][A-Za-z0-9+.-]*:/ ? $addr : "mailto:$addr";
}

sub _sentByAddress {
  my $Prop = shift;
  my $v = $Prop->{params}{'sent-by'} && $Prop->{params}{'sent-by'}[0];
  return undef unless defined $v;
  $v =~ s/^mailto://i;
  return length $v ? $v : undef;
}

# DELEGATED-FROM and DELEGATED-TO are lists of quoted cal-addresses
# (RFC 5545 3.2.4, 3.2.5), which the parser hands back joined with commas.
# Split them again, but only before something that starts a URI, so a
# comma inside an address survives.
sub _splitCalAddresses {
  return grep { length } map { split /,(?=[A-Za-z][A-Za-z0-9+.-]*:)/ } grep { defined } @_;
}

sub _makeParticipant {
  my ($Self, $Calendar, $Participants, $VAttendee, $role, $AddrKeys) = @_;

  my $email = $VAttendee->{value};
  return unless $email;
  $email =~ s/^mailto://i;
  return if $email eq '';
  # jscalendar-icalendar 2.1.3: a JSID MUST be used as the key.  ORGANIZER
  # and ATTENDEE with the same address are one participant, so a JSID on
  # either of them keys both.
  my $id = _propJSID($VAttendee)
        // ($AddrKeys && $AddrKeys->{lc $email})
        // sha1_hex(lc $email);

  $Participants->{$id} ||= {};

  # XXX - if present on one but not the other, take the "best" version
  $Participants->{$id}{name} = $VAttendee->{params}{"cn"}[0] // "";
  $Participants->{$id}{email} = $VAttendee->{params}{"email"}[0] // $email;
  $Participants->{$id}{calendarAddress} = "mailto:$email";
  $Participants->{$id}{kind} = lc $VAttendee->{params}{"cutype"}[0]
    if $VAttendee->{params}{"cutype"};
  $Participants->{$id}{roles}{$role} = $JSON::true;
  # we don't support locationId yet
  if ($VAttendee->{params}{"partstat"}) {
    $Participants->{$id}{participationStatus} = lc($VAttendee->{params}{"partstat"}[0] // "needs-action");
  }
  if ($VAttendee->{params}{"role"}) {
    my $ical_role = uc($VAttendee->{params}{"role"}[0] || '');
    if ($ical_role eq 'CHAIR') {
      $Participants->{$id}{roles}{chair} = $JSON::true;
    }

    if ($ical_role eq 'OWNER') {
      $Participants->{$id}{roles}{owner} = $JSON::true;
    }

    $Participants->{$id}{roles}{optional} = $JSON::true
      if $ical_role eq 'OPT-PARTICIPANT';

    $Participants->{$id}{roles}{informational} = $JSON::true
      if $ical_role eq 'NON-PARTICIPANT';
  }
  if ($VAttendee->{params}{"rsvp"}) {
    $Participants->{$id}{expectReply} = lc($VAttendee->{params}{"rsvp"}[0] // "") eq 'yes' ? $JSON::true : $JSON::false;
  }
  # SENT-BY is a cal-address; sentBy an email address (jscalendarbis-22
  # 3.4.6, jscalendar-icalendar-29 2.3.4, 2.3.29)
  if (my $SentBy = _sentByAddress($VAttendee)) {
    $Participants->{$id}{sentBy} = $SentBy;
  }
  if (exists $VAttendee->{params}{"x-dtstamp"}) {
    my ($Date) = eval { $Self->_makeDateObj($VAttendee->{params}{"x-dtstamp"}[0], 'UTC', 'UTC') };
    $Participants->{$id}{"scheduleUpdated"} = $Date->iso8601() . 'Z' if $Date;
  }
  # memberOf is not supported

  if (exists $VAttendee->{params}{"x-sequence"}) {
    $Participants->{$id}{scheduleSequence} = $VAttendee->{params}{"x-sequence"}[0] // "";
  }

  if ($VAttendee->{params}{"schedule-agent"}) {
    $Participants->{$id}{scheduleAgent} = lc($VAttendee->{params}{"schedule-agent"}[0]);
  }

  if ($VAttendee->{params}{"delegated-from"}) {
    my %df;
    for my $uri (_splitCalAddresses(@{$VAttendee->{params}{"delegated-from"}})) {
      $df{$uri} = $JSON::true;
    }
    $Participants->{$id}{delegatedFrom} = \%df if %df;
  }

  if ($VAttendee->{params}{"delegated-to"}) {
    my %dt;
    for my $uri (_splitCalAddresses(@{$VAttendee->{params}{"delegated-to"}})) {
      $dt{$uri} = $JSON::true;
    }
    $Participants->{$id}{delegatedTo} = \%dt if %dt;
  }
}

sub _make_duration {
  my ($Self, $dtdur, $IsAllDay) = @_;

  my ($w, $d, $H, $M, $S) = (
    $dtdur->weeks,
    $dtdur->days,
    $dtdur->hours,
    $dtdur->minutes,
    $dtdur->seconds,
  );

  return 'PT0S' unless ($w || $d || $H || $M || $S);

  my @bits = ('P');
  push @bits, ($w, 'W') if $w;
  push @bits, ($d, 'D') if $d;
  if (not $IsAllDay and ($H || $M || $S)) {
    push @bits, 'T';
    push @bits, ($H, 'H') if $H;
    push @bits, ($M, 'M') if $M;
    push @bits, ($S, 'S') if $S;
  }

  return join ('', @bits);
}

=head2 $NewEvent = Text::JSCalendar->NormaliseEvent($Event);

Returns a copy of the event (the original is not changed) in a canonical
form for comparison: every property whose value is its default
(jscalendarbis-22, or RFC 8984 for the properties -22 reserved) is
removed, and so is an C<@type> that only repeats the type its position
already implies.  Empty maps and arrays are removed.  Everything else is
kept as it is: a property this module does not know, the contents of a
C<recurrenceOverrides> patch, and the C<@type> of the Event or Task and of
any trigger that is not an OffsetTrigger.

Inside a recurrence override, a patch whose path names a known object
(C<participants/p1>, C<alerts/a1/trigger>, C<locations>) has that object
normalised the same way.  A patched value is never removed for being the
default: in a patch it overrides the master, so C<"status": "confirmed">
says something that C<{}> does not.

=cut

# The @type an object may leave out because its position implies it
# (jscalendarbis-22 1.4.4).  The Event or Task itself is absent here: there
# @type says which of the two it is.  For a trigger this is the defaultType
# (3.5.1); an AbsoluteTrigger or unknown trigger keeps its @type.
my %ImpliedType = (
  links            => 'Link',
  locations        => 'Location',
  virtualLocations => 'VirtualLocation',
  recurrenceRule   => 'RecurrenceRule',
  byDay            => 'NDay',
  relatedTo        => 'Relation',
  participants     => 'Participant',
  alerts           => 'Alert',
  trigger          => 'OffsetTrigger',
);

sub NormaliseEvent {
  my ($class, $Event, $Root) = @_;

  $Root ||= '';

  my %Copy = %$Event;

  if (exists $Copy{'@type'} and defined $ImpliedType{$Root}
      and _safeeq($Copy{'@type'}, $ImpliedType{$Root})) {
    delete $Copy{'@type'};
  }

  # An AbsoluteTrigger or an unknown trigger: nothing below applies to it
  # (relativeTo's default is the OffsetTrigger's), so keep it as it is.
  return \%Copy if $Root eq 'trigger' and exists $Copy{'@type'};

  # Only the keys the table knows are normalised; any other key is kept.
  # (This used to delete every key not in the table, which wiped the
  # contents of override patches and triggers, and every @type.)
  my $Spec = $EventKeys{$Root} || {};
  foreach my $key (sort keys %$Spec) {
    next unless exists $Copy{$key};
    my ($keep, $value) = $class->_normaliseProp($Spec->{$key}, $key, $Copy{$key});
    if ($keep) { $Copy{$key} = $value }
    else       { delete $Copy{$key} }
  }

  return \%Copy;
}

# Normalise one property value under its %EventKeys entry.  Returns
# (1, $value) to keep it, or () to drop it as default or empty.
sub _normaliseProp {
  my ($class, $entry, $key, $value) = @_;
  my ($container, $type, undef, $default) = @$entry;

  if ($container) {
    # a map or array: null and empty are both "not set"
    return () unless defined $value;
    my @new = $class->_normaliseContainer($entry, $key, $value);
    return @new ? (1, $new[0]) : ();
  }

  if ($type eq 'object') {
    return (1, $value) unless ref($value) eq 'HASH';
    return (1, $class->NormaliseEvent($value, $key));
  }
  # not the shape we expect: keep it (a JSON boolean is a scalar here)
  return (1, $value) if ref($value) and not JSON::is_bool($value);
  if ($type eq 'bool') {
    return () if !!$default == !!$value;
    return (1, $value);
  }
  if ($type eq 'mailto') {
    return (1, $value ? lc $value : $value);
  }
  return () if _safeeq($default, $value);
  return (1, $value);
}

# The members of a map (container 2) or array (container 1).  An empty
# one is dropped (()), a malformed one kept as it is.
sub _normaliseContainer {
  my ($class, $entry, $key, $value, $keepEmpty) = @_;
  my ($container) = @$entry;

  if ($container == 2) {
    return $value unless ref($value) eq 'HASH';
    return $value if !%$value and $keepEmpty;
    return () unless %$value;
    my %new = map { $_ => $class->_normaliseMember($entry, $key, $value->{$_}) } keys %$value;
    return \%new;
  }

  return $value unless ref($value) eq 'ARRAY';
  return $value if !@$value and $keepEmpty;
  return () unless @$value;
  return [ map { $class->_normaliseMember($entry, $key, $_) } @$value ];
}

# One member of a map or array: an object or a patch is normalised, any
# other value (a boolean in a set, a string) is kept.
sub _normaliseMember {
  my ($class, $entry, $key, $value) = @_;
  my $type = $entry->[1];
  return $value unless ref($value) eq 'HASH';
  return $class->NormaliseEvent($value, $key) if $type eq 'object';
  return $class->_normalisePatch($value) if $type eq 'patch';
  return $value;
}

# A PatchObject (jscalendarbis-22 1.4.9).  Each path that resolves to a
# known object position has its value normalised as that object; a value
# is never dropped (a patch setting a default overrides the master), and
# a path that does not resolve is kept untouched.
sub _normalisePatch {
  my ($class, $Patch) = @_;

  my %new;
  foreach my $path (keys %$Patch) {
    my $value = $Patch->{$path};
    my ($where, $entry, $key) = _patchTarget($path);
    if (!$where or ref($value) ne 'HASH' && ref($value) ne 'ARRAY') {
      $new{$path} = $value;
    }
    elsif ($where eq 'member') {
      # participants/p1, byDay/0: one object of the map or array
      $new{$path} = $entry->[1] eq 'object'
        ? $class->_normaliseMember($entry, $key, $value) : $value;
    }
    elsif ($entry->[0]) {
      # a whole map or array: an empty one is still a patch
      $new{$path} = $class->_normaliseContainer($entry, $key, $value, 1);
    }
    elsif ($entry->[1] eq 'object' and ref($value) eq 'HASH') {
      $new{$path} = $class->NormaliseEvent($value, $key);
    }
    else {
      $new{$path} = $value;
    }
  }

  return \%new;
}

# Where a patch path points in %EventKeys: ('prop', $entry, $name) for a
# property, ('member', $entry, $name) for one member of a map or array
# property, or () when it is not a position the table describes.
sub _patchTarget {
  my $path = shift;
  my @segs = map { _unquotekey($_) } split m{/}, $path, -1;
  my $table = '';
  while (@segs) {
    my $name = shift @segs;
    my $entry = ($EventKeys{$table} || {})->{$name} or return ();
    return ('prop', $entry, $name) unless @segs;
    if ($entry->[0]) {
      shift @segs;   # the map key or array index
      return ('member', $entry, $name) unless @segs;
    }
    # deeper in: only into an object with a table of its own
    return () unless $entry->[1] eq 'object' and $EventKeys{$name};
    $table = $name;
  }
  return ();
}

=head2 Text::JSCalendar->CompareEvents($Event1, $Event2);

Returns true if the events are the same once normalised (see
C<NormaliseEvent>).

=cut

sub CompareEvents {
  my ($class, $Event1, $Event2) = @_;

  my $E1 = $class->NormaliseEvent($Event1);
  my $E2 = $class->NormaliseEvent($Event2);

  return _safeeq($E1, $E2);
}

# Text::VCardFast recurses once per BEGIN, in C: nesting tens of thousands
# deep overflows the stack and kills the process (no eval can catch that).
# Real iCalendar nests four or so (VCALENDAR, VEVENT, VALARM); refuse
# anything deeper than this before it gets there.
our $MAX_NESTING = 16;
sub _nesting_ok {
  my ($text) = @_;
  my ($depth, $max) = (0, 0);
  while ($text =~ /^(BEGIN|END)[ \t]*:/mgi) {
    if (uc $1 eq 'BEGIN') { $depth++; return 0 if $depth > $MAX_NESTING }
    else { $depth-- if $depth > 0 }
  }
  return 1;
}

sub _getEventsFromVCalendar {
  my ($Self, $VCalendar) = @_;

  confess "Error parsing VCalendar data: components nested more than $MAX_NESTING deep\n"
    unless _nesting_ok($VCalendar);
  my $CalendarData = eval { vcard2hash($VCalendar, multival => ['rrule'], only_one => 1) }
    or confess "Error parsing VCalendar data: $@\n\n$VCalendar";

  my @Events;

  foreach my $Calendar (@{$CalendarData->{objects} || []}) {
    next unless lc $Calendar->{type} eq 'vcalendar';

    my $method = $Calendar->{properties}{method}[0]{value};
    my $prodid = $Calendar->{properties}{prodid}[0]{value};

    foreach my $VEvent (@{$Calendar->{objects} || []}) {
      my $type = lc($VEvent->{type} // '');
      next unless $type eq 'vevent' || $type eq 'vtodo';
      # each component on its own: one that cannot be converted is
      # dropped (and reported by errors()), not the whole calendar
      my $Event = eval { $Self->_vEventToEvent($Calendar, $VEvent, $method, $prodid) };
      if ($Event) {
        push @Events, $Event;
      }
      else {
        $Self->_error($VEvent->{properties}{uid}[0]{value}, uc $type, $@);
      }
    }
  }

  return \@Events;
}

# One VEVENT or VTODO as an Event or Task.  Dies if it cannot be
# converted; a bad VALARM or RRULE in it is dropped and reported instead.
sub _vEventToEvent {
  my ($Self, $Calendar, $VEvent, $method, $prodid) = @_;

  my $is_task = lc $VEvent->{type} eq 'vtodo';

  # parse simple component properties {{{

  my %Properties
    = map { $_ => $VEvent->{properties}{$_}[0] }
        keys %{$VEvent->{properties}};

  my $uid = $Properties{uid}{value};
  # Case: UID is badly broken or missing -
  # let's just calculate a UID based on the incoming data.  This
  # is the 'ICS sync url with no UIDs in it' case from BTS-3205,
  # http://mozorg.cdn.mozilla.net/media/caldata/DutchHolidays.ics
  $uid = _hexkey($VEvent) . '-syncauto' unless _saneuid($uid);

  my $ShowAsFree = (lc($Properties{transp}{value} || '')) eq 'transparent';

  # clean up whitespace on text fields
  foreach my $Property (qw{description location summary}) {
    next unless defined $Properties{$Property}{value};
    $Properties{$Property}{value} =~ s/^\s+//gs;
    $Properties{$Property}{value} =~ s/\s+$//gs;
  }

  my @description;
  push @description, $Properties{description}{value}
    if defined $Properties{description}{value};

  # }}}

  # parse time component properties {{{

  my ($IsAllDay, $Start, $StartTimeZone, $End, $EndTimeZone) = ('') x 5;

  confess "$uid: DTSTART not specified" unless defined $Properties{dtstart}{value};

  ($Start, $StartTimeZone, $IsAllDay) = $Self->_getDateObj($Calendar, $Properties{dtstart});

  if (defined $Properties{dtend}{value}) {
    if (defined $Properties{duration}{value}) {
      $Self->_warning($uid, uc $VEvent->{type}, "DTEND and DURATION cannot both be set; DURATION ignored");
    }

    ($End, $EndTimeZone) = $Self->_getDateObj($Calendar, $Properties{dtend});
  }
  elsif (defined $Properties{duration}{value}) {
    my $Duration = DateTime::Format::ICal->parse_duration(uc $Properties{duration}{value});
    $End = $Start->clone()->add($Duration);
    $EndTimeZone = $StartTimeZone;
  }
  else {
    $End         = $Start->clone();
    $EndTimeZone = $StartTimeZone;
  }

  if (DateTime->compare($Start, $End) > 0) {
    # swap em!
    ($Start, $End) = ($End, $Start);
    ($StartTimeZone, $EndTimeZone) = ($EndTimeZone, $StartTimeZone);
  }

  if ($IsAllDay and $StartTimeZone) {
    $Self->_warning($uid, uc $VEvent->{type}, "all-day DTSTART with time zone $StartTimeZone");
  }

  # if one is set, make sure they are both set
  $StartTimeZone ||= $EndTimeZone;
  $EndTimeZone   ||= $StartTimeZone;

  # }}}

  my %Recurrence;

  if (exists $Properties{rrule}) {
    # a rule that cannot be read drops only itself (see errors())
    my $ok = eval {
      my %RRULE;

      foreach my $RRULE (@{$Properties{rrule}{values}}) {
        my ($Key,$Value) = split '=', $RRULE;
        next unless defined $Value;

        $RRULE{lc $Key} = $Value;
      }

      # parse simple recurrence properties {{{

      if (exists $RRULE{freq}) {
        my $freq = lc $RRULE{freq};
        unless ($ValidFrequency{$freq}) {
          confess "$uid: Invalid recurrence FREQ ($freq)";
        }

        $Recurrence{frequency} = $freq;
      }
      else {
        confess "$uid: Recurrence FREQ not specified";
      }

      if (exists $RRULE{interval}) {
        unless ($RRULE{interval} =~ /^\d+$/) {
          confess "$uid: Invalid recurrence INTERVAL ($RRULE{interval})";
        }
        my $interval = int $RRULE{interval};

        if ($interval == 0) {
          confess "$uid: Recurrence INTERVAL is out of range ($RRULE{interval})";
        }

        # default == 1, so don't set a key for it
        if ($interval > 1) {
          $Recurrence{interval} = $interval;
        }
      }

      if (exists $RRULE{rscale}) {
        $Recurrence{rscale} = lc $RRULE{rscale};
        $Recurrence{skip} = lc $RRULE{skip} if $RRULE{skip};
      }

      if (exists $RRULE{wkst}) {
        my $wkst = lc $RRULE{wkst};
        unless ($ValidDay{$wkst}) {
          confess "$uid: Invalid recurrence WKST ($wkst)";
        }

        # default is Monday, so don't set a key for it
        if ($wkst ne 'mo') {
          $Recurrence{firstDayOfWeek} = $wkst;
        }
      }

      if (exists $RRULE{byday}) {
        my @byDays;

        foreach my $BYDAY (split ',', $RRULE{byday}) {
          push @byDays, _BYDAY2byDay(lc $BYDAY);
        }

        $Recurrence{byDay} = \@byDays if @byDays;
      }

      if (exists $RRULE{bymonth}) {
        foreach my $BYMONTH (split ',', $RRULE{bymonth}) {
          unless ($BYMONTH =~ /^\d+L?$/) {
            confess "$uid: Invalid recurrence BYMONTH ($BYMONTH, $RRULE{bymonth})";
          }

          push @{$Recurrence{byMonth}}, "$BYMONTH";
        }
      }

      if (exists $RRULE{count}) {
        if (exists $RRULE{until}) {
          #confess "$uid: Recurrence COUNT and UNTIL cannot both be set";
          # seen in the wild: PRODID:-//dmfs.org//mimedir.icalendar//EN
          delete $RRULE{until};
        }

        unless ($RRULE{count} =~ /^\d+$/) {
          confess "$uid: Invalid recurrence COUNT ($RRULE{count})";
        }

        $Recurrence{count} = int $RRULE{count};
      }

      if (exists $RRULE{until}) {
        # rfc5545 3.3.10 - UNTIL must be in DTSTART timezone, but both
        # google and iCloud store it in Z, so we will too as per rfc2445.
        my ($Until, $IsAllDay) = $Self->_makeDateObj($RRULE{until}, $StartTimeZone, $StartTimeZone);
        $Recurrence{until} = $Until->iso8601();
      }

      # }}}

      # parse generic recurrence properties {{{

      foreach my $Property (keys %RecurrenceProperties) {
        if (defined $RRULE{$Property}) {
          foreach my $Value (split ',', $RRULE{$Property}) {
            my ($Valid, $Min) = $RecurrenceProperties{$Property}{signed}
              ? ('[-+]?[1-9]\d*', ($RecurrenceProperties{$Property}{max} * -1))
              : ('\d+', 0);

            unless ($Value =~ /^$Valid$/) {
              confess "$uid: Invalid recurrence $Property ($Value)";
            }

            unless (($Value >= $Min) and ($Value <= $RecurrenceProperties{$Property}{max})) {
              confess "$uid: Recurrence $Property is out of range ($Value)";
            }

            push @{$Recurrence{$RecurrenceProperties{$Property}{name}}}, int $Value;
          }
        }
      }

      # }}}
      1;
    };
    unless ($ok) {
      %Recurrence = ();
      $Self->_error($uid, 'RRULE', $@);
    }
  }

  my %Overrides;
  if (exists $VEvent->{properties}{exdate}) {
    foreach my $Item (@{$VEvent->{properties}{exdate}}) {
      foreach my $Date ($Self->_getDateObjMulti($Calendar, $Item, $StartTimeZone)) {
        $Overrides{$Date->iso8601()} = { excluded => $JSON::true }; # 4.3.3
      }
    }
  }

  if ($VEvent->{properties}{rdate}) {
    # rdate      = "RDATE" rdtparam ":" rdtval *("," rdtval) CRLF
    foreach my $Item (@{$VEvent->{properties}{rdate}}) {
      # a PERIOD's start is the key and its length the patch's
      # duration (jscalendar-icalendar-29 2.3.33)
      if (lc($Item->{params}{value}[0] || '') eq 'period') {
        my $TimeZone = $Self->_getTimeZone($Calendar, $Item);
        foreach my $Period (split /,/, $Item->{value}) {
          my ($From, $To) = split m{/}, $Period, 2;
          my ($Date) = eval { $Self->_makeDateObj($From, $TimeZone, $StartTimeZone) } or next;
          my $Length;
          if (defined $To and $To =~ /^[+-]?P/i) {
            $Length = eval { DateTime::Format::ICal->parse_duration(uc $To) };
          }
          elsif (defined $To) {
            my ($Until) = eval { $Self->_makeDateObj($To, $TimeZone, $StartTimeZone) };
            $Length = $Until->subtract_datetime($Date) if $Until;
          }
          $Overrides{$Date->iso8601()} = ($Length && !$Length->is_negative)
            ? { duration => $Self->_make_duration($Length) } : {};
        }
        next;
      }
      foreach my $Date ($Self->_getDateObjMulti($Calendar, $Item, $StartTimeZone)) {
        $Overrides{$Date->iso8601()} = {};
      }
    }
  }

  # parse alarms {{{

  my %Alerts;
  foreach my $VAlarm (@{$VEvent->{objects} || []}) {
    next unless lc $VAlarm->{type} eq 'valarm';
    # a bad alarm drops only itself (see errors())
    my $alarmuid;
    my $ok = eval {

      my %AlarmProperties
        = map { $_ => $VAlarm->{properties}{$_}[0] }
            keys %{$VAlarm->{properties}};

      $alarmuid = $AlarmProperties{uid}{value}
                  || $AlarmProperties{'x-wr-alarmuid'}{value}
                  || _hexkey($VAlarm, $uid) . '-alarmauto';

      my %Alert;
      $Alert{'@type'} = 'Alert';

      # ACTION is required (RFC 5545 3.6.6)
      my $AlarmAction = lc($AlarmProperties{action}{value} // die "VALARM without ACTION\n");
      return 1 unless $AlarmAction;

      if ($AlarmAction eq 'display' || $AlarmAction eq 'audio') {
        $Alert{action} = 'display';
      }
      elsif ($AlarmAction eq 'email') {
        $Alert{action} = 'email';
      }
      elsif ($AlarmAction eq 'none') {
        return 1;
      }
      else {
        die "unknown VALARM ACTION $AlarmAction\n";
      }

      if ($AlarmProperties{acknowledged}) {
        my $date = $Self->_getDateObj($Calendar, $AlarmProperties{acknowledged}, 'UTC');
        $Alert{acknowledged} = $date->iso8601() . 'Z';
      }

      my $Trigger = $AlarmProperties{trigger}{value}
        || return 1;

      my $Related = (lc ($AlarmProperties{trigger}{params}{related}[0] || '') eq 'end')
        ? 'end'
        : 'start';

      if ($Trigger =~ m/^[+-]?P/i) {
        my $Duration = eval { DateTime::Format::ICal->parse_duration(uc $Trigger) }
          || return 1;

        my ($IsNeg, $OffsetStr);
        if ($Duration->is_negative()) {
          $Duration = $Duration->inverse();
          $IsNeg = 1;
        }
        # jscalendarbis-22 3.5.1: on a Task, "end" MUST NOT be used
        # without a due.  RFC 5545 3.8.6.3 puts such a VTODO's end at
        # DTSTART + DURATION, so say the same instant relative to start.
        if ($is_task and $Related eq 'end' and not $Properties{due}{value}) {
          my $Span = $End->subtract_datetime($Start);
          $Duration = $IsNeg ? $Span->clone->subtract_duration($Duration)
                             : $Span->clone->add_duration($Duration);
          $IsNeg = 0;
          if ($Duration->is_negative()) {
            $Duration = $Duration->inverse();
            $IsNeg = 1;
          }
          $Related = 'start';
        }
        $OffsetStr = ($IsNeg ? '-' : '') . $Self->_make_duration($Duration);
        $Alert{trigger} = {
          '@type'      => 'OffsetTrigger',
          'offset'     => $OffsetStr,
          'relativeTo' => $Related,
        };
      }
      else {
        # Absolute trigger (VALUE=DATE-TIME)
        my $AlertDate = $Self->_getDateObj($Calendar, $AlarmProperties{trigger}, 'UTC');
        $Alert{trigger} = {
          '@type' => 'AbsoluteTrigger',
          'when'  => $AlertDate->iso8601() . 'Z',
        };
      }

      $Alerts{$alarmuid} = \%Alert;
      1;
    };
    $Self->_error($uid, 'VALARM', $@, $alarmuid) unless $ok;
  }

  # }}}

  # parse attendees {{{

  my %Participants;
  my %AddrKeys;
  for my $VProp (@{$VEvent->{properties}{organizer} || []},
                 @{$VEvent->{properties}{attendee} || []}) {
    my $jsid = _propJSID($VProp) // next;
    my $addr = $VProp->{value} // next;
    $addr =~ s/^mailto://i;
    $AddrKeys{lc $addr} //= $jsid;
  }
  for my $VOrganizer (@{$VEvent->{properties}{organizer} || []}) {
    $Self->_makeParticipant($Calendar, \%Participants, $VOrganizer, 'owner', \%AddrKeys);
  }
  for my $VAttendee (@{$VEvent->{properties}{attendee} || []}) {
    $Self->_makeParticipant($Calendar, \%Participants, $VAttendee, 'attendee', \%AddrKeys);
  }

  # }}}

  # parse attachments {{{

  my %Links;
  foreach my $Attach (@{$VEvent->{properties}{attach} || []}) {
    next unless $Attach->{value};

    my $uri;
    my $encoding = lc($Attach->{params}{encoding}[0] || '');
    if ($encoding eq 'base64' || $encoding eq 'b') {
      # Binary ATTACH - convert to data: URI
      my $mime = $Attach->{params}{fmttype}[0] || 'application/octet-stream';
      $uri = "data:$mime;base64," . $Attach->{value};
    }
    elsif (grep { $Attach->{value} =~ m{^$_://} } qw{http https ftp data}) {
      $uri = $Attach->{value};
    }
    else {
      next;
    }

    my $filename = $Attach->{params}{filename}[0];
    my $mime = $Attach->{params}{fmttype}[0];
    if (not defined $mime and $filename) {
      $MimeTypes ||= MIME::Types->new;
      my $MimeTypeObj = $MimeTypes->mimeTypeOf($filename);
      $mime = $MimeTypeObj->type() if $MimeTypeObj;
    }

    my $size = $Attach->{params}{size}[0];

    $Links{_propJSID($Attach) // sha1_hex(lc $uri)} = {
      href => $uri,
      rel => 'enclosure',
      defined $filename ? (title => $filename) : (),
      defined $mime ? (contentType => $mime) : (),
      (defined $size && $size =~ /^\d+$/) ? (size => 0+$size) : (),
    };
  }
  # URL -> a link with rel "describedby", its title in LABEL
  # (jscalendar-icalendar 2.3.46)
  foreach my $URL (@{$VEvent->{properties}{url} || []}) {
    my $uri = $URL->{value};
    next unless $uri;
    $Links{_propJSID($URL) // sha1_hex(lc $uri)} = {
      href => $uri,
      rel => 'describedby',
      _linkTitle($URL, 'label'),
    };
  }
  # IMAGE -> a link with rel "icon", its title in FILENAME
  # (jscalendar-icalendar 2.3.22; LABEL, which this module used to
  # write, is still read)
  foreach my $Image (@{$VEvent->{properties}{image} || []}) {
    my $uri = $Image->{value};
    next unless $uri;
    my $size = $Image->{params}{size}[0];
    my @display = map { lc } grep { length } map { split /,/ } @{$Image->{params}{display} || []};
    $Links{_propJSID($Image) // sha1_hex(lc $uri)} = {
      href => $uri,
      rel => 'icon',
      defined $Image->{params}{fmttype}[0] ? (contentType => $Image->{params}{fmttype}[0]) : (),
      (defined $size && $size =~ /^\d+$/) ? (size => 0+$size) : (),
      @display ? (display => { map { $_ => $JSON::true } @display }) : (),
      _linkTitle($Image, 'filename', 'label'),
    };
  }
  # LINK with value type URI (jscalendar-icalendar 2.3.24): LINKREL is
  # the rel, LABEL the title; any other value type does not convert
  foreach my $Link (@{$VEvent->{properties}{link} || []}) {
    my $uri = $Link->{value};
    next unless $uri;
    next unless lc($Link->{params}{value}[0] // 'uri') eq 'uri';
    my $rel = $Link->{params}{linkrel}[0];
    $Links{_propJSID($Link) // sha1_hex(lc $uri)} = {
      href => $uri,
      defined $rel && length $rel ? (rel => $rel) : (),
      defined $Link->{params}{fmttype}[0] ? (contentType => $Link->{params}{fmttype}[0]) : (),
      _linkTitle($Link, 'label'),
    };
  }

  # }}}

  # parse CONFERENCE -> virtualLocations {{{

  my %VirtualLocations;
  foreach my $Conference (@{$VEvent->{properties}{conference} || []}) {
    next unless $Conference->{value};
    my $id = $Conference->{params}{'x-jmap-id'}[0] || sha1_hex($Conference->{value});
    my %vloc = ('@type' => 'VirtualLocation', uri => $Conference->{value});
    if ($Conference->{params}{label}) {
      $vloc{name} = $Conference->{params}{label}[0];
    }
    if ($Conference->{params}{feature}) {
      my @features = map { lc $_ } map { split /,/ } @{$Conference->{params}{feature}};
      $vloc{features} = { map { $_ => $JSON::true } @features };
    }
    $VirtualLocations{$id} = \%vloc;
  }

  # }}}

  # Parse keywords {{{

  my %keywords;
  foreach my $Categories (@{$VEvent->{properties}{categories} || []}) {
    my $val = $Categories->{value};
    $keywords{$_} = $JSON::true for split ',', $val;
  }
  delete $keywords{''}; # just in case it was created by leading or trailing ,

  # }}}

  # Parse relations {{{

  my %relations;
  foreach my $Relation (@{$VEvent->{properties}{'related-to'} || []}) {
    my $reltype = $Relation->{params}{reltype}[0] || 'parent';
    $reltype = lc $reltype if grep { $_ eq lc $reltype } qw(first next parent child);
    $relations{$Relation->{value}}{'@type'} = 'Relation';
    $relations{$Relation->{value}}{relation}{$reltype} = $JSON::true;
  }

  # }}}

  my %Event = ();

  # ==============================================================
  # 4.1 Metadata

  # 4.1.1 @type (JSCalendar bis uses capitalized names)
  $Event{'@type'} = $is_task ? 'Task' : 'Event';

  # 4.1.2 uid
  $Event{uid} = "$uid";

  # 4.1.3 relatedTo
  $Event{relatedTo} = \%relations if %relations;

  # 4.1.4 prodId
  $Event{prodId} = $prodid if defined $prodid;

  # 4.1.5 created
  if ($Properties{created}{value}) {
    # UTC item
    my $Date = eval { $Self->_getDateObj($Calendar, $Properties{created}, 'UTC') };
    $Event{created} = $Date->iso8601() . 'Z' if $Date;
  }

  # 4.1.6 updated
  if ($Properties{dtstamp}{value}) {
    # UTC item
    my $Date = eval { $Self->_getDateObj($Calendar, $Properties{dtstamp}, 'UTC') };
    $Event{updated} = $Date->iso8601() . 'Z' if $Date;
  }
  if (not $Event{updated} and $Properties{'last-modified'}{value}) {
    # UTC item
    my $Date = eval { $Self->_getDateObj($Calendar, $Properties{'last-modified'}, 'UTC') };
    $Event{updated} = $Date->iso8601() . 'Z' if $Date;
  }
  $Event{updated} ||= DateTime->now->iso8601();

  # 4.1.7 sequence
  # (a value that is not an integer is ignored; it used to die, when
  # the module made every warning fatal)
  my $sequence = _intValue($Properties{sequence}{value});
  $Event{sequence} = $sequence if defined $sequence;

  # 4.1.8 method
  $Event{method} = $method if $method;

  # ==============================================================
  # 4.2 What and where

  # 4.2.1 title
  $Event{title} = $Properties{summary}{value}
    if ($Properties{summary} and defined $Properties{summary}{value});

  # 4.2.2 description
  # STYLED-DESCRIPTION overrides DESCRIPTION if present
  if ($Properties{'styled-description'}{value}) {
    $Event{description} = $Properties{'styled-description'}{value};
    $Event{descriptionContentType} = $Properties{'styled-description'}{params}{fmttype}[0] // 'text/html';
  }
  elsif (@description) {
    $Event{description} = join("\n", @description);
  }

  # 4.2.4 locations
  if ($Properties{location}{value}) {
    $Event{locations}{location} = { '@type' => 'Location', name => $Properties{location}{value} };
  }
  # X-APPLE-STRUCTURED-LOCATION -> location with coordinates, name, description
  # Check for Apple structured locations first; if present, skip plain GEO
  my $has_apple_location = scalar @{$VEvent->{properties}{'x-apple-structured-location'} || []};

  # GEO -> separate location with coordinates (only if no Apple structured location)
  if (!$has_apple_location && $Properties{geo}{value}) {
    my ($lat, $lon) = split /;/, $Properties{geo}{value};
    if (defined $lat && defined $lon) {
      my $coords = "geo:$lat,$lon";
      my $locid = $Event{locations} ? 'geo' : 'location';
      $Event{locations}{$locid} = { '@type' => 'Location', coordinates => $coords };
    }
  }

  for my $ASL (@{$VEvent->{properties}{'x-apple-structured-location'} || []}) {
    next unless $ASL->{value};
    my %loc = ('@type' => 'Location');
    if ($ASL->{value} =~ m{^geo:([-\d.]+),([-\d.]+)}) {
      $loc{coordinates} = $ASL->{value};
    }
    my $title = $ASL->{params}{'x-title'}[0];
    $loc{name} = $title if defined $title && $title ne '';
    my $address = $ASL->{params}{'x-address'}[0];
    $loc{description} = $address if defined $address && $address ne '';
    if (keys %loc > 1) {  # more than just @type
      my $locid = sha1_hex($ASL->{value} || 'apple-location');
      $Event{locations}{$locid} = \%loc;
    }
  }

  # 4.2.5 virtualLocations
  $Event{virtualLocations} = \%VirtualLocations if %VirtualLocations;

  # 4.2.6 links
  $Event{links} = \%Links if %Links;

  # 4.2.7 locale
  my $language;
  if ($Properties{description} and $Properties{description}{params}{language}) {
    $language = $Properties{description}{params}{language}[0];
  }
  if ($Properties{summary} and $Properties{summary}{params}{language}) {
    $language = $Properties{summary}{params}{language}[0];
  }
  $Event{locale} = $language if $language;

  # 4.2.8 keywords
  $Event{keywords} = \%keywords if %keywords;

  # 4.2.9 categories is not supported

  # 4.2.10 color
  # (one the module cannot read is dropped: it used to die, taking the
  # whole calendar with it)
  if ($Properties{color}) {
    my $color = eval { _fixColor($Properties{color}{value}) };
    $Event{color} = $color if defined $color;
  }

  # ==============================================================
  # 4.3 Recurrence properties

  # 4.3.1 recurrenceRule (a singular object since jscalendarbis-15)
  if (%Recurrence) {
    $Recurrence{'@type'} = 'RecurrenceRule';
    $Event{recurrenceRule} = \%Recurrence;
  }

  # 4.3.2 recurrenceOverrides
  $Event{recurrenceOverrides} = \%Overrides if %Overrides;

  # ... special case for recurrence overrides when processing the child ...
  if ($Properties{'recurrence-id'}{value}) {
    # in our system it's always in the timezone of the event, but iCloud
    # returns it in UTC despite the event having a timezone.  Super weird.
    # Anyway, we need to format it to the StartTimeZone of the parent
    # event if there is one, and we don't have that yet!
    $Event{_recurrenceObj} = $Self->_getDateObj($Calendar, $Properties{'recurrence-id'});
  }

  # ==============================================================
  # 4.4 Sharing and scheduling properties

  # 4.4.1 priority
  # default is 0, so a truth test is sufficient
  if (my $priority = _intValue($Properties{priority}{value})) {
    $Event{priority} = $priority;
  }

  # 4.4.2 freeBusyStatus
  if ($Properties{transp}{value}) {
    $Event{freeBusyStatus} = 'free' if lc($Properties{transp}{value}) eq 'transparent';
  }

  # 4.4.3 privacy (from CLASS property)
  if ($Properties{class}{value}) {
    my $cls = lc($Properties{class}{value});
    if ($cls eq 'confidential') { $Event{privacy} = 'secret' }
    # jscalendar-icalendar-29 2.3.7: any other value MUST be private
    elsif ($cls ne 'public') { $Event{privacy} = 'private' }
  }

  # 4.4.4 organizerCalendarAddress
  foreach my $partid (sort keys %Participants) { # later wins
    next unless $Participants{$partid}{roles}{owner};
    $Event{organizerCalendarAddress} = $Participants{$partid}{calendarAddress};
  }

  # sentBy (jscalendarbis-22 3.4.5): the ORGANIZER's SENT-BY
  # (jscalendar-icalendar-29 2.3.29), which needs an organizer
  if ($Event{organizerCalendarAddress}) {
    for my $VOrganizer (@{$VEvent->{properties}{organizer} || []}) {
      my $SentBy = _sentByAddress($VOrganizer) // next;
      $Event{sentBy} = $SentBy;
      last;
    }
  }

  # 4.4.5 participants
  $Event{participants} = \%Participants if %Participants;

  # ==============================================================
  # 4.5 Alerts

  # 4.5.1 alerts
  $Event{alerts} = \%Alerts if %Alerts;

  # version (jscalendarbis)
  $Event{version} = '2.0';

  # 4.6.1 localisations is not supported

  # ==============================================================
  # 5.1 JSEvent specific properties

  # 5.1.1 start
  $Event{start} = $Start->iso8601() if ref($Start);

  # 5.1.2 timeZone: not set for a DATE or a floating time (it can no
  # longer be null, jscalendarbis-22 3.6.1, jscalendar-icalendar-29 2.1.5)
  $Event{timeZone} = $StartTimeZone if not $IsAllDay and defined $StartTimeZone and length $StartTimeZone;

  # endTimeZone (jscalendarbis): set if end timezone differs from start
  if (!$IsAllDay && $EndTimeZone && $StartTimeZone && $EndTimeZone ne $StartTimeZone) {
    $Event{endTimeZone} = $EndTimeZone;
  }

  # 5.1.3 duration
  my $duration = $Self->_make_duration($End->subtract_datetime($Start), $IsAllDay);
  $Event{duration} = $duration if $duration;

  # 5.1.4 showWithoutTime (RFC 8984)
  $Event{showWithoutTime} = $IsAllDay ? $JSON::true : $JSON::false;
  # SHOW-WITHOUT-TIME property (for DATE-TIME events shown as all-day)
  if (!$IsAllDay && $Properties{'show-without-time'}{value}) {
    my $swt = lc($Properties{'show-without-time'}{value});
    $Event{showWithoutTime} = $JSON::true if $swt eq 'true' || $swt eq 'yes';
  }

  # 5.1.5 status
  if ($Properties{status}{value}) {
    $Event{status} = lc($Properties{status}{value}) if lc($Properties{status}{value}) ne 'confirmed';
  }

  # Task-specific properties (VTODO)
  if ($is_task) {
    if ($Properties{due}{value}) {
      my ($Due, $DueTz) = $Self->_getDateObj($Calendar, $Properties{due});
      $Event{due} = $Due->iso8601();
    }
    my $percent = _intValue($Properties{'percent-complete'}{value});
    $Event{percentComplete} = $percent if defined $percent;
    if ($Properties{'estimated-duration'}{value}) {
      $Event{estimatedDuration} = uc $Properties{'estimated-duration'}{value};
    }
    if ($Properties{completed}{value}) {
      $Event{progress} = 'completed';
    }
    elsif (lc($Properties{status}{value} || '') eq 'in-process') {
      $Event{progress} = 'in-process';
    }
    elsif (lc($Properties{status}{value} || '') eq 'cancelled') {
      $Event{progress} = 'cancelled';
    }
  }

  return \%Event;
}

# jscalendar-icalendar-29 3.2: DTSTART, DUE and RECURRENCE-ID are DATE
# only if showWithoutTime is true, there is no timeZone, and no time of
# day appears anywhere: start, due, the durations, until and the override
# keys.  Otherwise an event shown without time keeps its time and zone and
# says so with SHOW-WITHOUT-TIME.
sub _writesAsDate {
  my $Args = shift;
  return 0 unless $Args->{showWithoutTime};
  return 0 if defined $Args->{timeZone} && length $Args->{timeZone};
  my $midnight = sub { !defined $_[0] || $_[0] !~ /T/ || $_[0] =~ /T00:00(?::00(?:\.0+)?)?\z/ };
  my $whole_days = sub { !defined $_[0] || $_[0] !~ /T/ || $_[0] =~ /T(?:0+[HMS])*\z/ };
  my $rule = ref $Args->{recurrenceRule} eq 'HASH' ? $Args->{recurrenceRule}
           : ref $Args->{recurrenceRules} eq 'ARRAY' ? $Args->{recurrenceRules}[0] : undef;
  return 0 unless $midnight->($Args->{start}) && $midnight->($Args->{due})
              && $midnight->($Args->{recurrenceId}) && $midnight->($rule ? $rule->{until} : undef)
              && $whole_days->($Args->{duration}) && $whole_days->($Args->{estimatedDuration});
  for my $key (keys %{ ref $Args->{recurrenceOverrides} eq 'HASH' ? $Args->{recurrenceOverrides} : {} }) {
    return 0 unless $midnight->($key);
  }
  return 1;
}

sub _getTimeZone {
  my $Self = shift;
  my ($Calendar, $Element) = @_;

  if ($Element->{value} =~ m/Z$/) {
    return 'Etc/UTC';
  }

  my $TZID = $Element->{params}{tzid}[0];

  return undef unless $TZID;

  return $Self->{_tznamemap}{$TZID} if exists $Self->{_tznamemap}{$TZID};

  my %TzOffsets;

  foreach my $VTimeZone (@{$Calendar->{objects} || []}) {
    next unless lc $VTimeZone->{type} eq 'vtimezone';
    next unless ($VTimeZone->{properties}{tzid}[0]{value} || '') eq $TZID;

    foreach my $Observance (@{$VTimeZone->{objects} || []}) {
      next unless grep { (lc $Observance->{type} || '') eq $_ } qw{standard daylight};
      next unless defined $Observance->{properties}{tzoffsetto}[0]{value};

      $TzOffsets{lc $Observance->{type}}
        = $Observance->{properties}{tzoffsetto}[0]{value};
    }
  }

  my $TimeZone = Text::JSCalendar::TimeZones->GetTimeZone(
    TZID               => $TZID,
    Time               => $Element->{value},
    (exists $TzOffsets{standard}
      ? (StandardTzOffsetTo => $TzOffsets{standard})
      : ()),
    (exists $TzOffsets{daylight}
      ? (DaylightTzOffsetTo => $TzOffsets{daylight})
      : ()),
  ) || undef;

  $Self->{_tznamemap}{$TZID} = $TimeZone;
  return $TimeZone;
}

sub _wireDate {
  # format: YYYY-MM-DDTHH:MM:SS Z?
  my $isoDate = shift;
  my $timeZone = shift || $FLOATING;
  confess "Invalid value (undefined) was not ISO8601" unless defined $isoDate;
  confess "Invalid value '$isoDate' was not ISO8601" unless $isoDate =~ m/^(\d{4,})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(Z?)$/i;
  $timeZone = 'Etc/UTC' if $7;

  my $Date = DateTime->_new(
    year => $1,
    month => $2,
    day => $3,
    hour => $4,
    minute => $5,
    second => $6,
    time_zone => $timeZone,
    locale => $LOCALE,
  ) or confess "Invalid value '$isoDate'";

  return $Date;
}

sub _vDate {
  # format: :YYYYMMDDTHHMMSS (floating)
  # format: :YYYYMMDDTHHMMSSZ (UTC)
  # format: ;TZID=X/Y:YYMMDDTHHMMSS (zoned)
  # format: ;TYPE=DATE:YYYYMMDD (but we don't know about that)
  my $vDate = shift;

  if ($vDate =~ m/^(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)(\.\d+)?(Z?)$/i) {
    my $Date = DateTime->_new(
      year => $1,
      month => $2,
      day => $3,
      hour => $4,
      minute => $5,
      second => $6,
      # ignore milliseconds in $7
      time_zone => ($8 eq 'Z' ? $UTC : $FLOATING),
      locale => $LOCALE,
    ) or confess "Invalid value '$vDate' for DATETIME";

    return ($Date, 1);
  }

  if ($vDate =~ m/^(\d\d\d\d)(\d\d)(\d\d)$/) {
    # all day
    my $Date = DateTime->_new(
      year => $1,
      month => $2,
      day => $3,
      time_zone => $FLOATING,
      locale => $LOCALE,
    ) or confess "Invalid value '$vDate' for DATE";

    return ($Date, 0);
  }

  # we only support those two patterns
  confess "Date '$vDate' was neither a DATE or DATETIME value";
}

sub _makeVTime {
  my $Self = shift;
  my ($TimeZones, $wire, $tz, $IsAllDay) = @_;

  my $date = _wireDate($wire, $tz);

  return $Self->_makeVTimeObj($TimeZones, $date, $tz, $IsAllDay);
}

sub _makeVTimeObj {
  my $Self = shift;
  my ($TimeZones, $date, $tz, $IsAllDay) = @_;

  # all day?
  if ($IsAllDay) {
    return [$date->strftime('%Y%m%d'), { VALUE => 'DATE' }];
  }

  # floating?
  unless ($tz) {
    return [$date->strftime('%Y%m%dT%H%M%S')];
  }

  # UTC?
  if ($UTCLinks{$tz}) {
    return [$date->strftime('%Y%m%dT%H%M%SZ')];
  }

  my $zone = $Self->tz($tz);

  $TimeZones->{$zone->name()} = 1;

  return [$date->strftime('%Y%m%dT%H%M%S'), { TZID => $zone->name() }];
}

sub _makeZTime {
  my ($Self, $date) = @_;
  return $Self->_makeVTime({}, $date, 'UTC');
}

sub _makeLTime {
  my $Self = shift;
  my ($TimeZones, $ltime, $tz, $IsAllDay) = @_;

  my $date = _wireDate($ltime, $Self->tz($tz));

  return [$date->strftime('%Y%m%d'), { VALUE => 'DATE' }] if $IsAllDay;

  unless ($tz) {
    # floating
    return [$date->strftime('%Y%m%dT%H%M%S')];
  }

  if ($tz =~ m/UTC/i) {
    return [$date->strftime('%Y%m%dT%H%M%SZ')];
  }

  # XXX - factor this crap out
  $TimeZones->{$tz} = 1;

  # XXX - use our cache
  my $zone = $Self->tz($tz);

  return [$date->strftime('%Y%m%dT%H%M%S'), { TZID => $zone->name() }];
}

sub _argsToVEvents {
  my $Self = shift;
  my ($TimeZones, $Args, $recurrenceData) = @_;
  my @VEvents;

  my $type = $Args->{'@type'} || '';
  my $is_task = $type eq 'Task';
  my $VEvent;
  if ($is_task) {
    eval { require Data::ICal::Entry::Todo };
    $VEvent = Data::ICal::Entry::Todo->new();
  } else {
    $VEvent = Data::ICal::Entry::Event->new();
  }

  # required properties
  my $transp = 'OPAQUE';
  if (defined $Args->{freeBusyStatus}) {
    $transp = 'TRANSPARENT' if $Args->{freeBusyStatus} eq 'free';
  }
  $VEvent->add_properties(
    uid      => $Args->{uid},
    sequence => ($Args->{sequence} || 0),
    ($is_task ? () : (transp => $transp)),
  );

  if ($recurrenceData) {
    my ($recurrenceId, $TopLevel) = @$recurrenceData;
    $VEvent->add_property('recurrence-id' => $Self->_makeLTime($TimeZones, $recurrenceId, $TopLevel->{timeZone}, _writesAsDate($TopLevel)));
    # (the same DATE-or-not decision as the master's DTSTART, -29 3.2)
  }

  # direct copy if properties exist
  if (defined $Args->{title} && $Args->{title} ne '') {
    my %lang;
    $lang{language} = $Args->{locale} if exists $Args->{locale};
    $VEvent->add_property(summary => [$Args->{title}, \%lang]);
  }
  if (defined $Args->{description} && $Args->{description} ne '') {
    my %lang;
    $lang{language} = $Args->{locale} if exists $Args->{locale};
    if ($Args->{descriptionContentType} && $Args->{descriptionContentType} ne 'text/plain') {
      # STYLED-DESCRIPTION for non-plain content types
      $VEvent->add_property('styled-description' => [$Args->{description}, { FMTTYPE => $Args->{descriptionContentType}, %lang }]);
    }
    else {
      $VEvent->add_property(description => [$Args->{description}, \%lang]);
    }
  }

  if ($Args->{status} and $Args->{status} ne 'confirmed') {
    $VEvent->add_property('status', uc($Args->{status}));
  }

  # privacy -> CLASS
  if ($Args->{privacy} && $Args->{privacy} ne 'public') {
    my $cls = $Args->{privacy} eq 'secret' ? 'CONFIDENTIAL' : uc($Args->{privacy});
    $VEvent->add_property('class' => $cls);
  }

  # priority
  if ($Args->{priority} && $Args->{priority} > 0) {
    $VEvent->add_property('priority' => $Args->{priority});
  }

  # color
  # COLOR is a CSS3 color name or a six-digit hex value (icalendar-
  # jscalendar-extensions-09 2.2); any other CSS color has no iCalendar form
  my $Color = $Args->{color} ? eval { _fixColor($Args->{color}) } : undef;
  if (defined $Color) {
    $VEvent->add_property('color' => $Color);
  }

  # dates in UTC - stored in UTC
  $VEvent->add_property(created => $Self->_makeZTime($Args->{created})) if $Args->{created};
  $VEvent->add_property(dtstamp => $Self->_makeZTime($Args->{updated} || DateTime->now->iso8601()));

  # dates in localtime - zones based on location
  my $EndTimeZone = $Args->{endTimeZone};
  my $locations = $Args->{locations} || {};
  foreach my $id (sort keys %$locations) {
    if ($locations->{$id}{name} && !$locations->{$id}{coordinates}) {
      # Only emit LOCATION if this entry doesn't also have coordinates
      # (coordinates with name go into X-APPLE-STRUCTURED-LOCATION with X-TITLE)
      $VEvent->add_property(location => $locations->{$id}{name});
    }
    # GEO from coordinates
    if ($locations->{$id}{coordinates} && $locations->{$id}{coordinates} =~ m{^geo:([-\d.]+),([-\d.]+)}) {
      my ($lat, $lon) = ($1, $2);
      my $has_apple_meta = $locations->{$id}{name};
      if ($has_apple_meta) {
        # Emit X-APPLE-STRUCTURED-LOCATION (which implies GEO)
        my %asl_params = (VALUE => 'URI');
        $asl_params{'X-TITLE'} = $locations->{$id}{name} if $locations->{$id}{name};
        $VEvent->add_property('x-apple-structured-location' => [$locations->{$id}{coordinates}, \%asl_params]);
      }
      else {
        # Plain GEO without Apple metadata
        $VEvent->add_property('geo' => "$lat;$lon");
      }
    }
  }

  my $StartTimeZone = $Args->{timeZone};
  my $IsAllDay = _writesAsDate($Args);
  my $Start = _wireDate($Args->{start}, $StartTimeZone);
  $VEvent->add_property(dtstart => $Self->_makeVTimeObj($TimeZones, $Start, $StartTimeZone, $IsAllDay));

  # SHOW-WITHOUT-TIME for DATE-TIME events displayed as all-day
  # (jscalendar-icalendar-29 2.3.38, 3.2)
  if ($Args->{showWithoutTime} && !$IsAllDay) {
    $VEvent->add_property('show-without-time' => ['TRUE', { VALUE => 'BOOLEAN' }]);
  }

  if ($Args->{duration}) {
    $EndTimeZone //= $StartTimeZone;
    my $Duration = eval { DateTime::Format::ICal->parse_duration($Args->{duration}) };
    my $End = $Start->clone()->add($Duration) if $Duration;
    $End->set_time_zone($EndTimeZone) if $EndTimeZone;
    $VEvent->add_property(dtend => $Self->_makeVTimeObj($TimeZones, $End, $EndTimeZone, $IsAllDay));
  }

  if (my $rule_def = $Args->{recurrenceRule}) {
    my %Recurrence = $Self->_makeRecurrence($rule_def, $IsAllDay, $StartTimeZone);

    # RFC 2445 4.3.10 - FREQ is the first part of the RECUR value type.
    # RFC 5545 3.3.10 - FREQ should be first to ensure backward compatibility.
    my $rule = join(';',
      ('FREQ=' . delete($Recurrence{FREQ})),
      (map { "$_=$Recurrence{$_}" } keys %Recurrence),
    );
    $VEvent->add_property(rrule => $rule);
  }

  my $Synthetic = isSyntheticMaster($Args);
  if ($Args->{recurrenceOverrides}) {
    foreach my $recurrenceId (sort keys %{$Args->{recurrenceOverrides}}) {
      my $val = $Args->{recurrenceOverrides}{$recurrenceId};
      if ($val->{excluded}) {
        # (no master to carry an EXDATE: the instance is simply not written)
        next if $Synthetic;
        $VEvent->add_property(exdate => $Self->_makeLTime($TimeZones, $recurrenceId, $StartTimeZone, $IsAllDay));
      }
      elsif (keys %$val or $Synthetic) {
        my $SubEvent = $Self->_maximise($Args, $val, $recurrenceId);
        push @VEvents, $Self->_argsToVEvents($TimeZones, $SubEvent, [$recurrenceId, $Args]);
      }
      else {
        $VEvent->add_property(rdate => $Self->_makeLTime($TimeZones, $recurrenceId, $StartTimeZone, $IsAllDay));
      }
    }
  }

  if ($Args->{alerts}) {
    # (an untitled event still gets a readable DESCRIPTION; the title was
    # interpolated undefined, which died under FATAL warnings)
    my $Title = $Args->{title} // '';
    for my $id (sort keys %{$Args->{alerts}}) {
      # a bad alert drops only itself (see errors())
      my $ok = eval {
        my $Alert = $Args->{alerts}{$id};

        my $trigger = $Alert->{trigger} // {};
        my $triggerType = $trigger->{'@type'} // 'OffsetTrigger';
        my $action = $Alert->{action} // 'display';

        my $VAlarm;
        if ($action eq 'email') {
          $VAlarm = Data::ICal::Entry::Alarm::Email->new();
          $VAlarm->add_property(summary => "Event alert: '$Title'");
          $VAlarm->add_property(description => "Event alert: '$Title'");
          if ($Args->{organizerCalendarAddress}) {
            $VAlarm->add_property(attendee => $Args->{organizerCalendarAddress});
          }
        }
        else {
          $VAlarm = Data::ICal::Entry::Alarm::Display->new();
        }

        if ($triggerType eq 'OffsetTrigger') {
          my $Offset   = $trigger->{offset} // 'PT0S';
          my $RelTo    = $trigger->{relativeTo} // 'start';
          # Offset may have a leading '-' sign (already encoded in the duration string)
          my $Sign     = ($Offset =~ s/^-//) ? '-' : '';
          my $Loc1     = $RelTo eq 'end' ? "ends" : "starts";
          my $Loc2     = $RelTo eq 'end' ? "ended" : "started";
          my $Minutes  = eval { DateTime::Format::ICal->parse_duration(uc $Offset)->in_units('minutes') } // 0;
          if ($action ne 'email') {
            $VAlarm->add_properties(
              description => (($Sign eq '-')
                ? "'$Title' $Loc1 in $Minutes minutes"
                : "'$Title' $Loc2 $Minutes minutes ago"),
            );
          }
          $VAlarm->add_property(uid => $id);
          if ($RelTo eq 'end') {
            $VAlarm->add_property(trigger => ["${Sign}$Offset", { RELATED => 'END' }]);
          }
          else {
            $VAlarm->add_property(trigger => "${Sign}$Offset");
          }
        }
        elsif ($triggerType eq 'AbsoluteTrigger') {
          my $When = $trigger->{when} // '';
          if ($action ne 'email') {
            $VAlarm->add_properties(
              description => "Event alert: '$Title'",
            );
          }
          $VAlarm->add_property(uid => $id);
          $VAlarm->add_property(trigger => [
            $Self->_makeZTime($When)->[0],
            { 'VALUE' => 'DATE-TIME' }
          ]);
        }
        else {
          confess "Unknown trigger type $triggerType";
        }

        if ($Alert->{acknowledged}) {
          $VAlarm->add_property(acknowledged => $Self->_makeZTime($Alert->{acknowledged}));
        }

        $VEvent->add_entry($VAlarm);
        1;
      };
      $Self->_error($Args->{uid}, 'Alert', $@, $id) unless $ok;
    }
  }

  my %namemap;
  my %keymap;
  my %sentbymap;
  if ($Args->{participants}) {
    foreach my $partid (sort keys %{$Args->{participants}}) {
      my $Attendee = $Args->{participants}{$partid};
      # jscalendarbis: a Participant's address is its calendarAddress URI;
      # "email" is the JSCalendar 1.0 form, still accepted.
      my $Uri = $Attendee->{calendarAddress}
             // (defined $Attendee->{email} ? "mailto:$Attendee->{email}" : undef);
      next unless defined $Uri;

      # jscalendar-icalendar 2.3.4: JSID carries the participant's key,
      # and may be left out only when the reader would arrive at the same
      # key anyway.  Without it, an override patching
      # participants/<key>/... no longer finds its participant.
      my $DefaultKey = _defaultParticipantKey($Uri);
      my $NeedJSID = !(defined $DefaultKey and $DefaultKey eq $partid);
      $keymap{lc $Uri} //= $partid if $NeedJSID;

      my %AttendeeProps;
      $AttendeeProps{JSID} = $partid if $NeedJSID;
      if ($Attendee->{"name"}) {
        $AttendeeProps{"CN"} = $Attendee->{"name"};
        $namemap{lc $Uri} = $Attendee->{"name"};
      }

      my $roles = ref($Attendee->{roles}) eq 'HASH'
        ? $Attendee->{roles}
        : { map { $_ => 1 } @{$Attendee->{roles} || []} };

      # jscalendarbis: every participant is an ATTENDEE unless the
      # ORGANIZER fully represents it (jscalendar-icalendar 3.6)
      unless ($roles->{attendee}) {
        my $OrgUri = $Args->{organizerCalendarAddress};
        next if defined $OrgUri and lc $OrgUri eq lc $Uri
          and not grep { $_ ne 'owner' } keys %$roles
          and not grep { !$OrganizerOnly{$_} } keys %$Attendee;
      }

      $AttendeeProps{"CUTYPE"}     = uc $Attendee->{"kind"} if defined $Attendee->{"kind"};
      $AttendeeProps{"RSVP"}       = "TRUE" if $Attendee->{"expectReply"};
      $AttendeeProps{"X-SEQUENCE"} = $Attendee->{"scheduleSequence"} if defined $Attendee->{"scheduleSequence"};
      $AttendeeProps{"X-DTSTAMP"}  = $Self->_makeZTime($Attendee->{"scheduleUpdated"}) if defined $Attendee->{"scheduleUpdated"};
      foreach my $prop (keys %AttendeeProps) {
        delete $AttendeeProps{$prop} if $AttendeeProps{$prop} eq '';
      }
      if ($roles->{owner}) {
        $AttendeeProps{ROLE} = 'OWNER';
      }
      elsif ($roles->{chair}) {
        $AttendeeProps{ROLE} = 'CHAIR';
      }
      elsif ($roles->{optional}) {
        $AttendeeProps{ROLE} = 'OPT-PARTICIPANT';
      }
      elsif ($roles->{informational}) {
        $AttendeeProps{ROLE} = 'NON-PARTICIPANT';
      }
      # default is REQ-PARTICIPANT
      $AttendeeProps{"SCHEDULE-AGENT"} = uc($Attendee->{scheduleAgent}) if $Attendee->{scheduleAgent};
      if ($Attendee->{delegatedFrom} && ref($Attendee->{delegatedFrom}) eq 'HASH') {
        $AttendeeProps{"DELEGATED-FROM"} = [ sort keys %{$Attendee->{delegatedFrom}} ];
      }
      if ($Attendee->{delegatedTo} && ref($Attendee->{delegatedTo}) eq 'HASH') {
        $AttendeeProps{"DELEGATED-TO"} = [ sort keys %{$Attendee->{delegatedTo}} ];
      }

      $AttendeeProps{PARTSTAT} = uc $Attendee->{"participationStatus"} if $Attendee->{"participationStatus"};
      if (defined $Attendee->{sentBy} and length $Attendee->{sentBy}) {
        $AttendeeProps{"SENT-BY"} = _mailto($Attendee->{sentBy});
        $sentbymap{lc $Uri} = $Attendee->{sentBy};
      }

      $VEvent->add_property(attendee => [ $Uri, \%AttendeeProps ]);
    }
  }
  if ($Args->{organizerCalendarAddress}) {
    my $OrgUri = $Args->{organizerCalendarAddress};
    my %OrgProps;
    my $CN = $namemap{lc $OrgUri};
    $OrgProps{CN} = $CN if $CN;
    # the organizer's participant may not be written as an ATTENDEE, so
    # its key must ride on the ORGANIZER (jscalendar-icalendar 2.3.29)
    $OrgProps{JSID} = $keymap{lc $OrgUri} if defined $keymap{lc $OrgUri};
    # the Event's sentBy, else the organizer participant's (-29 3.7)
    my $SentBy = $Args->{sentBy} // $sentbymap{lc $OrgUri};
    $OrgProps{"SENT-BY"} = _mailto($SentBy) if defined $SentBy and length $SentBy;
    $VEvent->add_property(organizer => [ $OrgUri, %OrgProps ? \%OrgProps : () ]);
  }

  if ($Args->{links}) {
    # jscalendar-icalendar 3.4: the property follows "rel" (whose default
    # is "enclosure", jscalendarbis 1.5.11): enclosure -> ATTACH, icon ->
    # IMAGE, the first describedby -> URL, anything else -> LINK.  The
    # title is FILENAME on ATTACH and IMAGE, LABEL on URL and LINK; LINKREL
    # goes on LINK only.  JSID carries the key unless the reader would
    # arrive at it anyway.
    my $HaveURL = 0;
    foreach my $key (sort keys %{$Args->{links}}) {
      my $Link = $Args->{links}{$key};
      next unless ref $Link eq 'HASH';
      my $Url = $Link->{href} // next;
      my $rel = $Link->{rel} // 'enclosure';
      my %Props;
      $Props{JSID} = $key unless $key eq sha1_hex(lc $Url);
      my $Name;
      if ($rel eq 'enclosure') {
        $Name = 'attach';
        $Props{FILENAME} = $Link->{title} if defined $Link->{title};
        $Props{SIZE} = $Link->{size} if defined $Link->{size};
      }
      elsif ($rel eq 'icon') {
        $Name = 'image';
        $Props{VALUE} = 'URI';
        $Props{FILENAME} = $Link->{title} if defined $Link->{title};
        $Props{SIZE} = $Link->{size} if defined $Link->{size};
        my @display = grep { $Link->{display}{$_} } sort keys %{ ref $Link->{display} eq 'HASH' ? $Link->{display} : {} };
        $Props{DISPLAY} = join(',', map { uc } @display) if @display;
      }
      elsif ($rel eq 'describedby' && !$HaveURL++) {
        $Name = 'url';
        $Props{LABEL} = $Link->{title} if defined $Link->{title};
      }
      else {
        $Name = 'link';
        $Props{VALUE} = 'URI';
        $Props{LINKREL} = $rel;
        $Props{LABEL} = $Link->{title} if defined $Link->{title};
      }
      $Props{FMTTYPE} = $Link->{contentType} if defined $Link->{contentType} && $Name ne 'url';
      $VEvent->add_property($Name => [ $Url, %Props ? \%Props : () ]);
    }
  }

  if ($Args->{relatedTo}) {
    foreach my $uid (keys %{$Args->{relatedTo}}) {
      my $relation = $Args->{relatedTo}{$uid}{relation};
      foreach my $key (keys %$relation) {
        $key = uc($key) if grep { $_ eq $key } qw(first next parent child);
        my %Props;
        $Props{RELTYPE} = $key unless $key eq 'PARENT';
        $VEvent->add_property('RELATED-TO' => [ $uid, \%Props ]);
      }
    }
  }

  if ($Args->{keywords}) {
    my @items = sort keys %{$Args->{keywords}};
    $VEvent->add_property('CATEGORIES', join(',', @items));
  }

  # virtualLocations -> CONFERENCE
  if ($Args->{virtualLocations}) {
    foreach my $id (sort keys %{$Args->{virtualLocations}}) {
      my $vloc = $Args->{virtualLocations}{$id};
      next unless $vloc->{uri};
      my %params = ('VALUE' => 'URI');
      $params{'X-JMAP-ID'} = $id;
      if ($vloc->{features} && ref($vloc->{features}) eq 'HASH') {
        my @feats = sort keys %{$vloc->{features}};
        $params{FEATURE} = join(',', map { uc $_ } @feats) if @feats;
      }
      $params{LABEL} = $vloc->{name} if defined $vloc->{name} && $vloc->{name} ne '';
      $VEvent->add_property(conference => [$vloc->{uri}, \%params]);
    }
  }

  # Task-specific properties (VTODO)
  if ($is_task) {
    if ($Args->{due}) {
      $VEvent->add_property(due => $Self->_makeLTime($TimeZones, $Args->{due}, $StartTimeZone, $IsAllDay));
    }
    if (defined $Args->{percentComplete}) {
      $VEvent->add_property('percent-complete' => $Args->{percentComplete});
    }
    if ($Args->{estimatedDuration}) {
      $VEvent->add_property('estimated-duration' => $Args->{estimatedDuration});
    }
    if ($Args->{progress} && $Args->{progress} eq 'completed') {
      $VEvent->add_property(completed => $Self->_makeZTime($Args->{updated} || DateTime->now->iso8601()));
    }
    elsif ($Args->{progress} && $Args->{progress} eq 'in-process') {
      $VEvent->add_property(status => 'IN-PROCESS');
    }
  }

  # a synthetic master (see SYNTHETIC_MASTER) has no component of its
  # own: only its instances are written
  unshift @VEvents, $VEvent unless $Synthetic;

  return @VEvents;
}

=head2 $self->eventsToVCalendar(@Events)

Convert a set of events (one or multiple) into an ical file)

Returns a string

e.g.

print $jscal->eventsToVCalendar(@Events);

=cut

sub eventsToVCalendar {
  my $Self = shift;
  $Self->_resetDiagnostics();
  my $VCalendar = $Self->_buildVCalendar(\@_);
  return $Self->_withICalWarnings(sub { $VCalendar->as_string() });
}

sub _argsToVCalendar {
  my $Self = shift;
  $Self->_resetDiagnostics();
  return $Self->_buildVCalendar(@_);
}

sub _buildVCalendar {
  my $Self = shift;
  my $Item = shift;
  my %ExtraProp = @_;
  return $Self->_withICalWarnings(sub { $Self->_buildVCalendarInner($Item, %ExtraProp) });
}

sub _buildVCalendarInner {
  my $Self = shift;
  my $Item = shift;
  my %ExtraProp = @_;

  my $VCalendar = Data::ICal->new();
  my $havepid = 0;

  foreach my $extra (keys %ExtraProp) {
    $VCalendar->add_properties($extra => $ExtraProp{$extra});
  }
  $VCalendar->add_properties(calscale => 'GREGORIAN');

  my @VEvents;
  my %TimeZones;
  foreach my $Args (ref $Item eq 'ARRAY' ? @$Item : $Item) {
    # each object on its own: one that cannot be written is left out
    # (and reported by errors()), not the whole calendar
    my %Zones;
    my @Converted = eval {
      die "not a JSCalendar object\n" unless ref $Args eq 'HASH';
      $Self->_argsToVEvents(\%Zones, $Args);
    };
    if (my $err = $@) {
      my $type = ref $Args eq 'HASH' && ($Args->{'@type'} // '') eq 'Task' ? 'Task' : 'Event';
      $Self->_error(ref $Args eq 'HASH' ? $Args->{uid} : undef, $type, $err);
      next;
    }
    push @VEvents, @Converted;
    @TimeZones{keys %Zones} = values %Zones;
    if (not $havepid and $Args->{prodId}) {
      $VCalendar->add_properties('prodid' => $Args->{prodId});
      $havepid = 1;
    }
  }

  # add timezone parts first
  foreach my $Zone (sort keys %TimeZones) {
    my $VTimeZone = Text::JSCalendar::TimeZones->GetVTimeZone($Zone);
    next unless $VTimeZone;
    $VCalendar->add_entry($VTimeZone);
  }

  # then the events
  foreach my $VEvent (@VEvents) {
    $VCalendar->add_entry($VEvent);
  }

  _sanitizeEntry($VCalendar);

  return $VCalendar;
}

# Data::ICal escapes newlines in values, but not a lone CR, and puts
# parameter values out verbatim, so a CR or LF from the event data
# would start a new content line.  RFC 5545 allows no control characters
# other than HTAB in either, so strip them before serialising.
sub _sanitizeEntry {
  my $Entry = shift;

  foreach my $Props (values %{$Entry->properties}) {
    foreach my $Prop (@$Props) {
      my $value = $Prop->value;
      if (defined $value and not ref $value) {
        $value =~ s/\r\n?/\n/g;
        $value =~ s/[\x00-\x08\x0b-\x1f\x7f]//g;
        $Prop->value($value);
      }

      my %params;
      while (my ($name, $val) = each %{$Prop->parameters}) {
        $params{$name} = ref $val eq 'ARRAY'
          ? [ map { _sanitizeParam($_) } @$val ]
          : _sanitizeParam($val);
      }
      $Prop->parameters(\%params);
    }
  }

  _sanitizeEntry($_) for @{$Entry->entries};
}

sub _sanitizeParam {
  my $val = shift;
  return $val unless defined $val;
  $val =~ s/[\r\n]+/ /g;
  # DQUOTE can't be escaped either; Data::ICal drops it with a warning
  $val =~ s/[\x00-\x08\x0a-\x1f\x7f"]//g;
  # nor a backslash: RFC 5545 gives it no meaning in a parameter, but
  # Text::VCardFast reads \; \: \" as escapes, so "Evil \" swallowed the
  # next parameter, or left the line unreadable
  $val =~ s/\\//g;
  return $val;
}

sub _makeRecurrence {
  my $Self = shift;
  my ($Args, $IsAllDay, $TZ) = @_;

  my %Recurrence;

  # validate simple recurrence properties {{{

  unless (ref($Args) eq 'HASH') {
    confess 'Invalid recurrence';
  }

  if ($Args->{frequency}) {
    unless ($ValidFrequency{$Args->{frequency}}) {
      confess "Invalid recurrence frequency ($Args->{frequency})";
    }

    $Recurrence{FREQ} = uc($Args->{frequency});
  }
  else {
    confess 'Recurrence frequency not specified';
  }

  # (numbers are copied before they meet a pattern or a join: either
  # stringifies the value it is given, and that would turn the caller's
  # 2 into "2" when it next encodes the object as JSON)
  if (defined $Args->{interval}) {
    my $interval = $Args->{interval};
    unless ($interval =~ /^\d+$/) {
      confess "Invalid recurrence interval ($interval)";
    }

    if ($interval == 0) {
      confess "Recurrence interval is out of range ($interval)";
    }

    if ($interval > 1) {
      $Recurrence{INTERVAL} = $interval;
    }
  }

  if (defined $Args->{firstDayOfWeek}) {
    unless ($ValidDay{$Args->{firstDayOfWeek}}) {
      confess "Invalid recurrence firstDayOfWeek ($Args->{firstDayOfWeek})";
    }

    unless ($Args->{firstDayOfWeek} eq 'mo') {
      $Recurrence{WKST} = uc $Args->{firstDayOfWeek};
    }
  }

  if ($Args->{byDay}) {
    unless (ref($Args->{byDay}) eq 'ARRAY') {
      confess 'Invalid recurrence byDay';
    }

    unless (@{$Args->{byDay}}) {
      confess 'Recurrence byDay is empty';
    }

    $Recurrence{BYDAY} = join(',', map{ _byDay2BYDAY($_) } @{$Args->{byDay}});
  }

  if ($Args->{byMonth}) {
    unless (ref($Args->{byMonth}) eq 'ARRAY') {
      confess 'Invalid recurrence byMonth';
    }

    unless (@{$Args->{byMonth}}) {
      confess 'Recurrence byMonth is empty';
    }

    my @BYMONTHS;

    foreach my $byMonthArg (@{$Args->{byMonth}}) {
      my $byMonth = $byMonthArg;
      unless ($byMonth =~ /^(\d+)L?$/i) {
        confess "Recurrence byMonth is not a number with optional L ($byMonth)";
      }
      my $monthNum = $1;
      unless ($monthNum >= 1 and $monthNum <= 13) {
        # not sure if 13 is OK
        confess "Recurrence byMonth is too high ($monthNum)";
      }

      push @BYMONTHS, $byMonth;
    }

    $Recurrence{BYMONTH} = join ',', @BYMONTHS;
  }

  if (defined $Args->{count}) {
    if (defined $Args->{until}) {
      confess 'Recurrence count and until cannot both be set';
    }

    my $count = $Args->{count};
    unless ($count =~ /^\d+$/) {
      confess "Invalid recurrence count ($count)";
    }

    $Recurrence{COUNT} = $count;
  }

  if ($Args->{until}) {
    my $Until = _wireDate($Args->{until}, $Self->tz($TZ));

    if ($IsAllDay) {
      $Recurrence{UNTIL} = $Until->strftime('%Y%m%d');
    }
    else {
      # API is in Localtime, but both iCloud and Google use 'Z' times as per
      # rfc2445, so we'll copy them for compatibility.
      $Until->set_time_zone($UTC);
      $Recurrence{UNTIL} = $Until->strftime('%Y%m%dT%H%M%SZ');
    }
  }

  if ($Args->{rscale}) {
    # written into the RRULE as they are: an rscale like "gregorian;COUNT=1"
    # would add rule parts past the checks below (RFC 7529: an rscale is a
    # calendar name; skip is one of three values)
    confess "recurrence rscale ($Args->{rscale}) is not valid" unless $Args->{rscale} =~ /\A[A-Za-z0-9-]{1,64}\z/;
    confess "recurrence skip ($Args->{skip}) is not valid"
      if exists $Args->{skip} && ($Args->{skip} // '') !~ /\A(?:omit|backward|forward)\z/i;
    $Recurrence{RSCALE} = uc $Args->{rscale};
    $Recurrence{SKIP} = uc $Args->{skip} if exists $Args->{skip};
  }

  # }}}

  # validate generic recurrence properties {{{

  foreach my $Property (keys %RecurrenceProperties) {
    my $Name = $RecurrenceProperties{$Property}{name}; 

    if ($Args->{$Name}) {
      unless (ref($Args->{$Name}) eq 'ARRAY') {
        confess "Invalid recurrence $Name";
      }

      unless (@{$Args->{$Name}}) {
        confess "Recurrence $Name is empty";
      }

      my @Values;

      foreach my $ValueArg (@{$Args->{$Name}}) {
        my $Value = $ValueArg;
        my ($Valid, $Min) = $RecurrenceProperties{$Property}{signed}
          ? ('[-+]?[1-9]\d*', ($RecurrenceProperties{$Property}{max} * -1))
          : ('\d+', 0);

        unless ($Value =~ /^$Valid$/) {
          confess "Invalid recurrence $Name ($Value)";
        }

        unless (($Min <= $Value) and ($Value <= $RecurrenceProperties{$Property}{max})) {
          confess "Recurrence $Name is out of range ($Value)";
        }

        push @Values, $Value;
      }

      $Recurrence{uc $Property} = join ',', @Values;
    }
  }

  # }}}

  return %Recurrence;
}

=head2 $self->vcalendarToEvents($Data)

Convert a text vcalendar (either a single event or an entire ical file) into an array of events.

Returns an array (not arrayref) of Events in UID order.

e.g.

    foreach my $Event ($CalDAV->vcalendarToEvents($Data)) {
        # ...
    }

=cut

sub _insert_override {
  my $Event = shift;
  my $recurrenceId = shift;
  my $Recurrence = shift;
  my $KeepEmpty = shift;

  my %override;
  my %oldkeys = map { $_ => 1 } keys %$Event;
  foreach my $Key (sort keys %$Recurrence) {
    delete $oldkeys{$Key};
    next if $MustBeTopLevel{$Key}; # XXX - check safeeq and die?
    if ($Key eq 'start') {
      # special case, it's the recurrence-id
      next if _safeeq($Recurrence->{start}, $recurrenceId);
      $override{start} = $Recurrence->{start};
      next;
    }
    next if _safeeq($Recurrence->{$Key}, $Event->{$Key});
    _add_override(\%override, _quotekey($Key), $Recurrence->{$Key}, $Event->{$Key});
  }

  foreach my $Key (sort keys %oldkeys) {
    next if $MustBeTopLevel{$Key};
    $override{$Key} = $JSON::null;
  }

  # in theory should never happen, but you could edit something back to be identical
  return unless %override or $KeepEmpty;
  $Event->{recurrenceOverrides}{$recurrenceId} = \%override;
}

sub vcalendarToEvents {
  my $Self = shift;
  my $Data = shift;

  # Internal caches need to be invalidated on each item read! A bit evil really...
  delete $Self->{_tznamemap};
  $Self->_resetDiagnostics();

  my %map;
  my %exceptions;
  my $Events = $Self->_getEventsFromVCalendar($Data);

  foreach my $Event (@$Events) {
    my $uid = $Event->{uid};
    if ($Event->{_recurrenceObj}) {
      push @{$exceptions{$uid}}, $Event;
    }
    elsif ($map{$uid}) {
      # it looks like sometimes Google doesn't remember to put the Recurrence ID
      # on additional recurrences after the first one, which is going to screw up
      # pretty badly because if the date has changed, then we can't even notice
      # which recurrent it was SUPPOSED to be.  *sigh*.
      $Self->_warning($uid, uc($Event->{'@type'} eq 'Task' ? 'VTODO' : 'VEVENT'),
        "a second component without RECURRENCE-ID; read as an instance at its DTSTART");
      push @{$exceptions{$uid}}, $Event;
      $map{$uid}{_dirty} = 1;
    }
    else {
      $map{$uid} = $Event;
    }
  }

  foreach my $uid (keys %exceptions) {
    unless ($map{$uid}) {
      # create a synthetic top-level, and say so (see SYNTHETIC_MASTER),
      # from the earliest instance, so that it does not depend on the
      # order of the components (the writer sorts them)
      my ($First) = sort { _compareInstances($a, $b) } @{$exceptions{$uid}};
      $map{$uid} = {
        SYNTHETIC_MASTER() => $JSON::true,
        uid => $uid,
        # required at top level, but may be different in recurrences
        # so not in MustBeTopLevel
        start => $First->{start},
        updated => $First->{updated},
        version => $First->{version},
      };
      $map{$uid}{timeZone} = $First->{timeZone} unless $First->{showWithoutTime};
      foreach my $key (keys %MustBeTopLevel) {
        $map{$uid}{$key} = $First->{$key} if exists $First->{$key};
      }
    }
    foreach my $SubEvent (@{$exceptions{$uid}}) {
      my $recurrenceId = $SubEvent->{start};
      if ($SubEvent->{_recurrenceObj}) {
        my $Date = delete $SubEvent->{_recurrenceObj};
        $Date->set_time_zone($map{$uid}{timeZone}) if $map{$uid}{timeZone};
        $recurrenceId = $Date->iso8601();
      }
      # every instance of a synthetic master is an override, even one
      # that patches nothing: there is no rule or RDATE to recur from
      _insert_override($map{$uid}, $recurrenceId, $SubEvent, isSyntheticMaster($map{$uid}));
    }
  }

  return map { $map{$_} } sort keys %map;
}

=head2 $self->instance($Event, $recurrenceId)

The occurrence of C<$Event> with the given recurrence id (a LocalDateTime
as used for C<recurrenceOverrides> keys, C<YYYY-MM-DDTHH:MM:SS>), as an
object of its own: a copy of the master with the override patch for that
id, if any, applied (PatchObject paths such as
C<participants/p1/participationStatus> included, as the writer applies
them), C<recurrenceId> set, C<recurrenceIdTimeZone> set to the master's
C<timeZone> if it has one, C<start> the patch's if it moves the
occurrence and the recurrence id otherwise, and C<recurrenceRule> and
C<recurrenceOverrides> removed.  A patch cannot change the properties an
occurrence must share with its master (C<uid>, C<@type>,
C<recurrenceRule>, ...; the same ones the writer ignores).

Returns undef if the occurrence is excluded, or if C<$Event> is a
synthetic master (see above) and the id is not one of its instances.
It does not check that the id is an occurrence of the rule: that is
what C<occurrences> is for.  C<$Event> is not changed.  May be called as
a class method.

=cut

sub instance {
  my ($Self, $Event, $recurrenceId) = @_;
  croak 'instance: not an event' unless ref $Event eq 'HASH';
  my $rid = _localDateTime($recurrenceId) // croak "instance: invalid recurrenceId";

  my $Overrides = ref $Event->{recurrenceOverrides} eq 'HASH' ? $Event->{recurrenceOverrides} : {};
  my $Patch = $Overrides->{$rid};
  $Patch = undef unless ref $Patch eq 'HASH';
  return undef if $Patch and $Patch->{excluded};
  return undef if !$Patch and isSyntheticMaster($Event);

  my $Instance = $Self->_maximise($Event, $Patch || {}, $rid);
  delete $Instance->{excluded};
  $Instance->{recurrenceId} = $rid;
  if (defined $Event->{timeZone}) {
    $Instance->{recurrenceIdTimeZone} = $Event->{timeZone};
  }
  else {
    delete $Instance->{recurrenceIdTimeZone};
  }
  return $Instance;
}

=head2 $self->occurrences($Event, after => $from, before => $to, max => $n)

The recurrence ids of C<$Event> (LocalDateTimes, C<YYYY-MM-DDTHH:MM:SS>,
the form of C<recurrenceOverrides> keys) that are at or after C<after>
and before C<before>, in order.  Both bounds are LocalDateTimes in the
event's own time zone (a trailing C<Z> is ignored, a bare date means its
midnight) and either may be left out.  These are:

=over

=item * the event's C<start>, which is always the first occurrence
(jscalendarbis-22 3.3.3.1), and for a C<recurrenceRule> every date-time
the rule produces from it, with every rule property this module reads:
C<frequency>, C<interval>, C<firstDayOfWeek>, C<byDay> (with
C<nthOfPeriod>), C<byMonthDay>, C<byMonth>, C<byYearDay>, C<byWeekNo>,
C<byHour>, C<byMinute>, C<bySecond>, C<bySetPosition>, C<count>,
C<until>, and C<skip> (C<rscale> must be C<gregorian>, the default;
another one dies),

=item * plus every C<recurrenceOverrides> key that is not excluded and
that the rule does not produce (an added occurrence, iCalendar's RDATE),

=item * minus every key whose patch sets C<excluded>.

=back

For a synthetic master (see above) they are its instances: its override
keys, minus the excluded ones.

C<max> (default 5000) bounds the number returned, so an unbounded rule
without C<before> still ends; a rule that stops matching (C<byMonthDay>
30 in C<byMonth> 2) ends once 400 years pass without an occurrence.
Returns an empty list for an event without C<start>.  May be called as
a class method.

=cut

our $MaxOccurrences = 5000;
# Bounds on one rule's expansion (a rule is untrusted input): the periods
# and candidate dates looked at, and the entries of any one BYxxx list.
our $MaxExpandWork = 250_000;
our $MaxRuleList   = 400;

sub occurrences {
  my ($Self, $Event, %Opts) = @_;
  croak 'occurrences: not an event' unless ref $Event eq 'HASH';
  my $max = $Opts{max} // $MaxOccurrences;
  croak 'occurrences: max must be a positive integer' unless $max =~ /^\d+$/ and $max > 0;
  my ($after, $before);
  if (defined $Opts{after}) {
    $after = _localDateTime($Opts{after}) // croak "occurrences: invalid after ($Opts{after})";
  }
  if (defined $Opts{before}) {
    $before = _localDateTime($Opts{before}) // croak "occurrences: invalid before ($Opts{before})";
  }
  my $inRange = sub {
    my $rid = shift;
    return 0 if defined $after and $rid lt $after;
    return 0 if defined $before and $rid ge $before;
    return 1;
  };

  my $Overrides = ref $Event->{recurrenceOverrides} eq 'HASH' ? $Event->{recurrenceOverrides} : {};
  my (%excluded, @added);
  foreach my $key (keys %$Overrides) {
    my $rid = _localDateTime($key) // next;
    my $Patch = $Overrides->{$key};
    if (ref $Patch eq 'HASH' and $Patch->{excluded}) { $excluded{$rid} = 1 }
    else { push @added, $rid }
  }

  my @found;
  unless (isSyntheticMaster($Event)) {
    my $start = _localDateTime($Event->{start}) // return ();
    my $Rule = $Event->{recurrenceRule};
    $Rule = undef unless ref $Rule eq 'HASH';
    my $limit = defined $before ? $before : undef;
    my $take = sub {
      my $rid = shift;
      return 1 if $excluded{$rid} or !$inRange->($rid);
      push @found, $rid;
      return @found < $max;
    };
    if ($Rule) {
      _expandRule($Rule, $start, $limit, $take, $after);
    }
    elsif (!defined $before or $start lt $before) {
      $take->($start);
    }
  }

  my %seen;
  my @all = sort grep { !$seen{$_}++ } @found, grep { !$excluded{$_} and $inRange->($_) } @added;
  splice @all, $max if @all > $max;
  return @all;
}

# A LocalDateTime in the canonical form of override keys, or undef.
# A trailing Z or fraction is dropped; a bare date is its midnight.
sub _localDateTime {
  my $value = shift;
  return undef unless defined $value and not ref $value;
  return "$1T00:00:00" if $value =~ /^(\d{4}-\d\d-\d\d)$/;
  return "$1T$2" if $value =~ /^(\d{4}-\d\d-\d\d)T(\d\d:\d\d:\d\d)(?:\.\d+)?Z?$/i;
  return undef;
}

# --- recurrence rule expansion (jscalendarbis-22 3.3.3.1) ---------------
#
# Days are counted from 1970-01-01 (day 0, a Thursday); weekdays are
# 0 (mo) to 6 (su).  Everything is local time: recurrence ids are.

my %DayNum = (mo => 0, tu => 1, we => 2, th => 3, fr => 4, sa => 5, su => 6);

sub _isLeap { my $y = shift; return ($y % 4 == 0 && $y % 100 != 0) || $y % 400 == 0 }

sub _daysInMonth {
  my ($y, $m) = @_;
  return 29 if $m == 2 and _isLeap($y);
  return (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$m - 1];
}

# days from civil and back (H. Hinnant's algorithms)
sub _dayNumber {
  my ($y, $m, $d) = @_;
  $y -= 1 if $m <= 2;
  my $era = int(($y >= 0 ? $y : $y - 399) / 400);
  my $yoe = $y - $era * 400;
  my $doy = int((153 * ($m + ($m > 2 ? -3 : 9)) + 2) / 5) + $d - 1;
  my $doe = $yoe * 365 + int($yoe / 4) - int($yoe / 100) + $doy;
  return $era * 146097 + $doe - 719468;
}

sub _civil {
  my $z = shift() + 719468;
  my $era = int(($z >= 0 ? $z : $z - 146096) / 146097);
  my $doe = $z - $era * 146097;
  my $yoe = int(($doe - int($doe / 1460) + int($doe / 36524) - int($doe / 146096)) / 365);
  my $y = $yoe + $era * 400;
  my $doy = $doe - (365 * $yoe + int($yoe / 4) - int($yoe / 100));
  my $mp = int((5 * $doy + 2) / 153);
  my $d = $doy - int((153 * $mp + 2) / 5) + 1;
  my $m = $mp + ($mp < 10 ? 3 : -9);
  return ($y + ($m <= 2 ? 1 : 0), $m, $d);
}

sub _weekday { return (shift() + 3) % 7 }   # day 0 was a Thursday

# The week number (and its year) of a day, weeks starting on $wkst, week
# 1 being the first with four days in the year; and how many weeks that
# year has.
sub _weekNo {
  my ($day, $wkst) = @_;
  my $weekStart = $day - ((_weekday($day) - $wkst) % 7);
  my ($wy) = _civil($weekStart + 3);
  my $ordinal = $weekStart + 3 - _dayNumber($wy, 1, 1);
  return (int($ordinal / 7) + 1, $wy);
}

sub _weeksInYear {
  my ($y, $wkst) = @_;
  my ($n) = _weekNo(_dayNumber($y, 12, 28), $wkst);
  return $n;
}

sub _list {
  my $v = shift;
  return undef unless ref $v eq 'ARRAY' and @$v;
  return $v;
}

# Calls $take->($recurrenceId) for each occurrence of $Rule from $start
# (the start itself first, always), in order, until it returns false,
# the rule ends, an occurrence reaches $before, or 400 years pass
# without one.
sub _expandRule {
  my ($Rule, $start, $before, $take, $after) = @_;

  my $freq = lc($Rule->{frequency} // '');
  croak "recurrence frequency ($freq) is not valid" unless $ValidFrequency{$freq};
  my $rscale = lc($Rule->{rscale} // 'gregorian');
  croak "recurrence rscale $rscale is not supported" unless $rscale eq 'gregorian';
  my $skip = lc($Rule->{skip} // 'omit');
  my $interval = $Rule->{interval} // 1;
  croak "recurrence interval ($interval) is not valid" unless $interval =~ /^\d+$/ and $interval >= 1;
  my $wkst = $DayNum{lc($Rule->{firstDayOfWeek} // 'mo')} // croak 'recurrence firstDayOfWeek is not valid';
  my $count = $Rule->{count};
  croak "recurrence count ($count) is not valid" if defined $count and $count !~ /^\d+$/;
  my $until;
  if (defined $Rule->{until}) {
    $until = _localDateTime($Rule->{until}) // croak "recurrence until ($Rule->{until}) is not valid";
  }

  my ($sy, $sm, $sd, $sH, $sM, $sS) = $start =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)$/;
  $_ += 0 for $sy, $sm, $sd, $sH, $sM, $sS;
  my $startDay = _dayNumber($sy, $sm, $sd);

  # the rule's parts, numbers checked, and those implied by the start
  my %by;
  foreach my $name (qw(byMonthDay byYearDay byWeekNo byHour byMinute bySecond bySetPosition)) {
    my $list = _list($Rule->{$name}) or next;
    $by{$name} = [ map { croak "recurrence $name ($_) is not valid" unless defined $_ and /^[-+]?\d+$/; 0 + $_ } @$list ];
  }
  # RFC 5545 S3.3.10's ranges (a negative day counts from the end), and no
  # list longer than any calendar could need: a rule is untrusted input,
  # and every entry is work in every period
  my %range = (byHour => [0, 23], byMinute => [0, 59], bySecond => [0, 60],
               byMonthDay => [-31, 31], byYearDay => [-366, 366], byWeekNo => [-53, 53],
               bySetPosition => [-366, 366]);
  foreach my $name (keys %range) {
    next unless $by{$name};
    croak "recurrence $name has too many entries" if @{$by{$name}} > $MaxRuleList;
    croak "recurrence $name is out of range"
      if grep { $_ < $range{$name}[0] or $_ > $range{$name}[1] or $_ == 0 && $range{$name}[0] < 0 } @{$by{$name}};
  }
  foreach my $name (qw(byMonth byDay)) {
    my $list = _list($Rule->{$name}) or next;
    croak "recurrence $name has too many entries" if @$list > $MaxRuleList;
  }
  if (my $list = _list($Rule->{byMonth})) {
    # a leap month ("5L") never matches in the Gregorian calendar
    $by{byMonth} = { map { (defined $_ and /^(\d+)$/) ? (0 + $1 => 1) : () } @$list };
  }
  if (my $list = _list($Rule->{byDay})) {
    $by{byDay} = [ map {
      croak 'recurrence byDay is not valid' unless ref $_ eq 'HASH' and defined $_->{day} and exists $DayNum{lc $_->{day}};
      [ $DayNum{lc $_->{day}}, $_->{nthOfPeriod} ? 0 + $_->{nthOfPeriod} : 0 ];
    } @$list ];
  }
  my $startDow = _weekday($startDay);
  $by{bySecond} //= [$sS] unless $freq eq 'secondly';
  $by{byMinute} //= [$sM] unless $freq eq 'secondly' or $freq eq 'minutely';
  $by{byHour}   //= [$sH] unless $freq eq 'secondly' or $freq eq 'minutely' or $freq eq 'hourly';
  if ($freq eq 'weekly' and !$by{byDay}) {
    $by{byDay} = [[$startDow, 0]];
  }
  if ($freq eq 'monthly' and !$by{byDay} and !$by{byMonthDay}) {
    $by{byMonthDay} = [$sd];
  }
  if ($freq eq 'yearly' and !$by{byYearDay}) {
    if (!$by{byMonth} and !$by{byWeekNo} and ($by{byMonthDay} or !$by{byDay})) {
      $by{byMonth} = { $sm => 1 };
    }
    if (!$by{byMonthDay} and !$by{byWeekNo} and !$by{byDay}) {
      $by{byMonthDay} = [$sd];
    }
    if ($by{byWeekNo} and !$by{byMonthDay} and !$by{byDay}) {
      $by{byDay} = [[$startDow, 0]];
    }
  }
  my $nthInYear = ($freq eq 'yearly' and !$by{byMonth});
  my %inList = map { $_ => { map { $_ => 1 } @{$by{$_} || []} } } qw(byHour byMinute bySecond);

  # does a (valid) day pass byMonth, byWeekNo, byYearDay, byMonthDay?
  my $dayMatchesUpToMonthDay = sub {
    my ($day, $y, $m, $d, $skipMonthDay) = @_;
    return 0 if $by{byMonth} and !$by{byMonth}{$m};
    if ($by{byWeekNo}) {
      my ($wn, $wy) = _weekNo($day, $wkst);
      my $total = _weeksInYear($wy, $wkst);
      return 0 unless grep { $_ > 0 ? $_ == $wn : $total + 1 + $_ == $wn } @{$by{byWeekNo}};
    }
    if ($by{byYearDay}) {
      my $yd = $day - _dayNumber($y, 1, 1) + 1;
      my $diy = _isLeap($y) ? 366 : 365;
      return 0 unless grep { $_ > 0 ? $_ == $yd : $diy + 1 + $_ == $yd } @{$by{byYearDay}};
    }
    if ($by{byMonthDay} and !$skipMonthDay) {
      my $dim = _daysInMonth($y, $m);
      return 0 unless grep { $_ > 0 ? $_ == $d : $dim + 1 + $_ == $d } @{$by{byMonthDay}};
    }
    return 1;
  };
  my $dayMatchesByDay = sub {
    my ($day, $y, $m, $d) = @_;
    return 1 unless $by{byDay};
    my $dow = _weekday($day);
    foreach my $bd (@{$by{byDay}}) {
      next unless $bd->[0] == $dow;
      return 1 unless $bd->[1];
      my ($pos, $len) = $nthInYear
        ? ($day - _dayNumber($y, 1, 1) + 1, _isLeap($y) ? 366 : 365)
        : ($d, _daysInMonth($y, $m));
      my $n = $bd->[1] > 0 ? int(($pos - 1) / 7) + 1 : -(int(($len - $pos) / 7) + 1);
      return 1 if $n == $bd->[1];
    }
    return 0;
  };

  # the candidate days of a year or month when skip moves invalid dates
  # (jscalendarbis-22 3.3.3.1, step 2): byMonthDay is applied to every
  # month as if it had 31 days, and an invalid date moves
  my $skipping = ($skip ne 'omit' and $by{byMonthDay} and ($freq eq 'yearly' or $freq eq 'monthly'));
  my $skipDays = sub {
    my ($y, @months) = @_;
    my %days;
    foreach my $m (@months) {
      next if $by{byMonth} and !$by{byMonth}{$m};
      my $dim = _daysInMonth($y, $m);
      foreach my $v (@{$by{byMonthDay}}) {
        my $day;
        if ($v > 0 and $v <= $dim) { $day = _dayNumber($y, $m, $v) }
        elsif ($v < 0 and $dim + 1 + $v >= 1) { $day = _dayNumber($y, $m, $dim + 1 + $v) }
        else {
          # invalid: byWeekNo and byYearDay never match it
          next if $by{byWeekNo} or $by{byYearDay};
          if ($v > 0) {
            $day = $skip eq 'forward' ? _dayNumber($y, $m, $dim) + 1 : _dayNumber($y, $m, $dim);
          }
          else {
            $day = $skip eq 'forward' ? _dayNumber($y, $m, 1) : _dayNumber($y, $m, 1) - 1;
          }
          $days{$day} = 1;
          next;
        }
        my (undef, undef, $d) = _civil($day);
        $days{$day} = 1 if $dayMatchesUpToMonthDay->($day, $y, $m, $d, 1);
      }
    }
    return grep { $dayMatchesByDay->($_, _civil($_)) } sort { $a <=> $b } keys %days;
  };

  # the days of a period that pass every date filter
  my $daysOf = sub {
    my ($first, $last) = @_;
    my @days;
    for my $day ($first .. $last) {
      my ($y, $m, $d) = _civil($day);
      push @days, $day if $dayMatchesUpToMonthDay->($day, $y, $m, $d) and $dayMatchesByDay->($day, $y, $m, $d);
    }
    return @days;
  };

  # the days of the given months of year $y that pass every date filter:
  # $daysOf over only the months byMonth allows, or, with byMonthDay (and
  # no byWeekNo or byYearDay to widen it), straight from its values -- not
  # every day of the year tested in turn
  my $daysOfMonths = sub {
    my ($y, @months) = @_;
    @months = grep { $by{byMonth}{$_} } @months if $by{byMonth};
    if ($by{byMonthDay} and !$by{byWeekNo} and !$by{byYearDay}) {
      my %days;
      foreach my $m (@months) {
        my $dim = _daysInMonth($y, $m);
        foreach my $v (@{$by{byMonthDay}}) {
          my $d = $v > 0 ? $v : $dim + 1 + $v;
          $days{_dayNumber($y, $m, $d)} = 1 if $d >= 1 and $d <= $dim;
        }
      }
      return grep { my @c = _civil($_); $dayMatchesUpToMonthDay->($_, @c) and $dayMatchesByDay->($_, @c) }
             sort { $a <=> $b } keys %days;
    }
    return map { $daysOf->(_dayNumber($y, $_, 1), _dayNumber($y, $_, _daysInMonth($y, $_))) } @months;
  };

  my @hours   = sort { $a <=> $b } keys %{$inList{byHour}};
  my @minutes = sort { $a <=> $b } keys %{$inList{byMinute}};
  my @seconds = sort { $a <=> $b } keys %{$inList{bySecond}};
  my $fmt = sub {
    my ($day, $H, $M, $S) = @_;
    my ($y, $m, $d) = _civil($day);
    return sprintf('%04d-%02d-%02dT%02d:%02d:%02d', $y, $m, $d, $H, $M, $S);
  };

  # the candidates of period $n, in order
  my $periodStart;   # the first date-time of the period, as a string
  my $noDays;        # no day of the period passed the date filters
  my $candidates = sub {
    my $n = shift;
    my (@days, @H, @M, @S);
    @H = @hours; @M = @minutes; @S = @seconds;
    if ($freq eq 'yearly') {
      my $y = $sy + $n * $interval;
      $periodStart = sprintf('%04d-01-01T00:00:00', $y);
      @days = $skipping ? $skipDays->($y, 1 .. 12) : $daysOfMonths->($y, 1 .. 12);
    }
    elsif ($freq eq 'monthly') {
      my $mi = ($sy * 12 + $sm - 1) + $n * $interval;
      my ($y, $m) = (int($mi / 12), $mi % 12 + 1);
      $periodStart = sprintf('%04d-%02d-01T00:00:00', $y, $m);
      @days = $skipping ? $skipDays->($y, $m) : $daysOfMonths->($y, $m);
    }
    elsif ($freq eq 'weekly') {
      my $first = $startDay - ((_weekday($startDay) - $wkst) % 7) + 7 * $n * $interval;
      $periodStart = $fmt->($first, 0, 0, 0);
      @days = $daysOf->($first, $first + 6);
    }
    elsif ($freq eq 'daily') {
      my $day = $startDay + $n * $interval;
      $periodStart = $fmt->($day, 0, 0, 0);
      @days = $daysOf->($day, $day);
    }
    else {
      my $unit = { hourly => 3600, minutely => 60, secondly => 1 }->{$freq};
      my $t = (($startDay * 24 + $sH) * 60 + $sM) * 60 + $sS;
      $t -= $t % $unit;
      $t += $n * $interval * $unit;
      my $day = int($t / 86400);
      $day-- if $t < 0 and $t % 86400;
      my $secs = $t - $day * 86400;
      my ($H, $M, $S) = (int($secs / 3600), int(($secs % 3600) / 60), $secs % 60);
      $periodStart = $fmt->($day, $H, $M, $freq eq 'secondly' ? $S : 0);
      @days = $daysOf->($day, $day);
      @H = $inList{byHour}{$H} || !%{$inList{byHour}} ? ($H) : ();
      if ($freq ne 'hourly') {
        @M = $inList{byMinute}{$M} || !%{$inList{byMinute}} ? ($M) : ();
      }
      if ($freq eq 'secondly') {
        @S = $inList{bySecond}{$S} || !%{$inList{bySecond}} ? ($S) : ();
      }
    }
    $noDays = !@days;
    my @out;
    foreach my $day (@days) {
      foreach my $H (@H) {
        foreach my $M (@M) {
          push @out, map { $fmt->($day, $H, $M, $_) } @S;
        }
      }
    }
    if ($by{bySetPosition}) {
      my @keep;
      foreach my $p (@{$by{bySetPosition}}) {
        my $i = $p > 0 ? $p - 1 : @out + $p;
        push @keep, $out[$i] if $i >= 0 and $i < @out;
      }
      my %u;
      @out = sort grep { !$u{$_}++ } @keep;
    }
    return @out;
  };

  my $produced = 0;
  my %seen;
  my $emit = sub {
    my $rid = shift;
    return 1 if $seen{$rid}++;
    return 0 if defined $until and $rid gt $until;
    return 0 if defined $before and $rid ge $before;
    return 0 if defined $count and $produced >= $count;
    $produced++;
    return $take->($rid) ? 1 : 0;
  };

  # the start is always the first occurrence
  return unless $emit->($start);

  # how many periods may pass without an occurrence: 400 years' worth
  my $idle = { yearly => 400, monthly => 4800, weekly => 20871, daily => 146097,
               hourly => 3506328, minutely => 210379680, secondly => 12622780800 }->{$freq};
  $idle = int($idle / $interval) + 1;
  my $sinceLast = 0;
  # a sub-daily rule on a day no date filter lets through skips the day
  my $subDaily = ($freq eq 'hourly' or $freq eq 'minutely' or $freq eq 'secondly');

  # without a count, the periods before the one holding $after cannot
  # matter: start there (one early, for a date a skip moved forward)
  my $n0 = 0;
  if (defined $after and !defined $count and $after gt $start) {
    my ($ay, $am, $ad, $aH, $aM, $aS) = map { 0 + $_ } $after =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)$/;
    my $aDay = _dayNumber($ay, $am, $ad);
    my $steps;
    if ($freq eq 'yearly') { $steps = ($ay - $sy) }
    elsif ($freq eq 'monthly') { $steps = ($ay * 12 + $am) - ($sy * 12 + $sm) }
    elsif ($freq eq 'weekly') { $steps = int(($aDay - $startDay) / 7) }
    elsif ($freq eq 'daily') { $steps = $aDay - $startDay }
    else {
      my $unit = { hourly => 3600, minutely => 60, secondly => 1 }->{$freq};
      my $secs = ((($aDay - $startDay) * 24 + $aH - $sH) * 60 + $aM - $sM) * 60 + $aS - $sS;
      $steps = int($secs / $unit);
    }
    $n0 = int($steps / $interval) - 1;
    $n0 = 0 if $n0 < 0;
  }

  # a hard bound on the work one expansion may do: whatever the rule, it
  # ends after this many periods and candidates looked at
  my $work = 0;
  for (my $n = $n0; ; $n++) {
    my @c = $candidates->($n);
    return if ($work += 1 + @c) > $MaxExpandWork;
    return if defined $until and $periodStart gt $until;
    return if defined $before and $periodStart ge $before;
    my $any = 0;
    foreach my $rid (@c) {
      next if $rid lt $start;
      $any = 1;
      return unless $emit->($rid);
    }
    if ($any) { $sinceLast = 0 }
    elsif (++$sinceLast > $idle) { return }
    elsif ($subDaily and $noDays) {
      # jump to the last period that starts on this day
      my $unit = { hourly => 3600, minutely => 60, secondly => 1 }->{$freq};
      my ($H, $M, $S) = $periodStart =~ /T(\d\d):(\d\d):(\d\d)$/;
      my $left = int((86400 - ($H * 3600 + $M * 60 + $S) - 1) / ($unit * $interval));
      $n += $left;
      $sinceLast += $left;
    }
    elsif ($subDaily and !@c) {
      # the day passed but this period's hour (or minute) did not: jump to
      # the last period that starts before the next allowed one, as above
      # for a day (MINUTELY;BYHOUR=9 looked at every minute of the day)
      my $unit = { hourly => 3600, minutely => 60, secondly => 1 }->{$freq};
      my ($H, $M, $S) = map { 0 + $_ } $periodStart =~ /T(\d\d):(\d\d):(\d\d)$/;
      my $now = $H * 3600 + $M * 60 + $S;
      my $next;
      if (%{$inList{byHour}} and !$inList{byHour}{$H}) {
        my ($h) = grep { $_ > $H } @hours;
        $next = defined $h ? $h * 3600 : 86400;
      }
      elsif ($freq ne 'hourly' and %{$inList{byMinute}} and !$inList{byMinute}{$M}) {
        my ($m) = grep { $_ > $M } @minutes;
        $next = $H * 3600 + (defined $m ? $m * 60 : 3600);
      }
      if (defined $next) {
        my $left = int(($next - $now - 1) / ($unit * $interval));
        $n += $left;
        $sinceLast += $left;
      }
    }
  }
}

# Order two instances by their RECURRENCE-ID (then DTSTART)
sub _compareInstances {
  my ($A, $B) = @_;
  my ($ra, $rb) = map { $_->{_recurrenceObj} } $A, $B;
  if ($ra and $rb) {
    my $c = DateTime->compare($ra, $rb);
    return $c if $c;
  }
  return ($ra ? 0 : 1) <=> ($rb ? 0 : 1) || ($A->{start} // '') cmp ($B->{start} // '');
}

sub _quotekey {
  my $key = shift;
  $key =~ s/\~/~0/gs;
  $key =~ s/\//~1/gs;
  return $key;
}

sub _unquotekey {
  my $key = shift;
  $key =~ s/\~1/\//gs;
  $key =~ s/\~0/~/gs;
  return $key;
}

sub _add_override {
  my ($override, $prefix, $New, $Old) = @_;

  # basic case - it's not an object, so we just override
  if (ref($New) ne 'HASH' or ref($Old) ne 'HASH') {
    $override->{$prefix} = $New;
    return;
  }

  # XXX - if too many, we could just abort...
  my %subover;
  my %oldkeys = map { $_ => 1 } keys %$Old;
  foreach my $Key (sort keys %$New) {
    delete $oldkeys{$Key};
    next if _safeeq($New->{$Key}, $Old->{$Key});
    _add_override(\%subover, "$prefix/" . _quotekey($Key), $New->{$Key}, $Old->{$Key});
  }
  foreach my $Key (sort keys %oldkeys) {
    $subover{"$prefix/" . _quotekey($Key)} = $JSON::null;
  }

  # which one is better?
  if (length(encode_json($New)) < length(encode_json(\%subover))) {
    $override->{$prefix} = $New; # cheaper to just encode the whole object
  }
  else {
    $override->{$_} = $subover{$_} for keys %subover;
  }
}

sub _apply_patch {
  my $path = shift;
  my $hash = shift;
  my $value = shift;

  return unless $path =~ s{^([^/]+)(/?)}{};
  return unless ref($hash) eq 'HASH';
  my $qkey = $1;
  my $slash = $2;
  my $key = _unquotekey($qkey);
  if ($slash) {
    _apply_patch($path, $hash->{$key}, $value);
  }
  elsif(defined $value) {
    $hash->{$key} = $value;
  }
  else {
    delete $hash->{$key};
  }
}

sub _maximise {
  my $Self = shift;
  my $Event = shift;
  my $Recurrence = shift;
  my $recurrenceId = shift;

  # a copy of the master without its rule and overrides (copying them for
  # every override and then dropping them made writing an event O(N^2) in
  # its overrides)
  my %master = %$Event;
  delete @master{'recurrenceRule', 'recurrenceOverrides', SYNTHETIC_MASTER()};
  my $new = _deepcopy(\%master);
  $new->{start} = $recurrenceId;

  foreach my $path (sort keys %$Recurrence) {
    # overrides can't change the identity or type of the master event
    my ($first) = $path =~ m{^([^/]*)};
    my $key = _unquotekey($first);
    next if $MustBeTopLevel{$key};
    next if $path =~ m{^participants/[^/]+/calendarAddress$};
    my $value = $Recurrence->{$path};
    _apply_patch($path, $new, $value);
  }

  return $new;
}

sub _stripNonICal {
  my $Self = shift;
  my $Event = shift;

  delete $Event->{alerts};
  delete $Event->{participants};
  delete $Event->{organizerCalendarAddress};

  foreach my $exception (values %{$Event->{recurrenceOverrides} || {}}) {
    next unless ref($exception) eq 'HASH';
    $Self->_stripNonICal($exception);
  }
}

sub _safeeq {
  my ($a, $b) = @_;
  my $json = JSON::XS->new->canonical;
  return $json->encode([$a]) eq $json->encode([$b]);
}

sub _deepcopy {
  my $data = shift;
  my $json = JSON::XS->new->canonical;
  my $enc = $json->encode([$data]);
  my $copy = $json->decode($enc);
  return $copy->[0];
}


=head1 AUTHOR

Bron Gondwana, C<< <brong at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2019-2026 Fastmail Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself; that is, either the GNU General
Public License as published by the Free Software Foundation (version 1,
or at your option any later version), or the Artistic License.

See L<http://dev.perl.org/licenses/> and the LICENSE file included with
this distribution for more information.

=cut

1; # End of Text::JSCalendar
