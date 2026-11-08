#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::XS ();
use Encode ();
use Text::JSCalendar;

# Round trips through the whole converter, compared on the raw structures
# (not through NormaliseEvent), so that any drift between the reader
# (_getEventsFromVCalendar) and the writer (_argsToVEvents) shows up.
#
#   A. JSCalendar -> iCalendar -> JSCalendar is the identity, for the
#      hand-written Events and Tasks in testdata/roundtrip/*.json, which
#      between them use every property the module converts.
#   B. iCalendar -> JSCalendar -> iCalendar -> JSCalendar is stable (the
#      two JSCalendar results are identical) for every .ics file under
#      testdata/, including the conversion examples of
#      draft-ietf-calext-jscalendar-icalendar-29 (testdata/
#      jscalendar-icalendar-29, made by tools/extract-icalendar-examples.pl).
#   C. Known conversion bugs that A and B do not reach.
#
# Known failures are TODO, each with a one-line reason; this file records
# them, it does not fix them.  When a fix lands, its TODO starts passing
# ("unexpectedly succeeded") and the entry should be removed.

my $jscal = Text::JSCalendar->new();
my $JSON = JSON::XS->new->canonical;

# The @type an object may leave out because its position implies it
# (jscalendarbis-22 1.4.4).  The reader adds it to some objects and not to
# others (never to a Participant or Link), and the fixtures set it
# everywhere, so it is removed from both sides before comparing.  The
# Event/Task @type and that of a non-Offset trigger stay.
my %MemberType = (
  links => 'Link', locations => 'Location', virtualLocations => 'VirtualLocation',
  participants => 'Participant', alerts => 'Alert', relatedTo => 'Relation',
);

sub strip_types {
  my ($obj, $type) = @_;
  return unless ref $obj eq 'HASH';
  delete $obj->{'@type'} if defined $type and ($obj->{'@type'} // '') eq $type;
  for my $key (keys %$obj) {
    my $v = $obj->{$key};
    if ($MemberType{$key} and ref $v eq 'HASH') {
      strip_types($_, $MemberType{$key}) for values %$v;
    }
    elsif ($key eq 'recurrenceRule') {
      strip_types($v, 'RecurrenceRule');
      strip_types($_, 'NDay') for @{ ref $v eq 'HASH' && ref $v->{byDay} eq 'ARRAY' ? $v->{byDay} : [] };
    }
    elsif ($key eq 'trigger') {
      strip_types($v, 'OffsetTrigger');
    }
  }
  # override patches: a whole map, or one member of it
  for my $patch (values %{ ref $obj->{recurrenceOverrides} eq 'HASH' ? $obj->{recurrenceOverrides} : {} }) {
    next unless ref $patch eq 'HASH';
    for my $path (keys %$patch) {
      my ($first, $id, $rest) = split m{/}, $path, 3;
      next unless $MemberType{$first} and not defined $rest;
      if (defined $id) { strip_types($patch->{$path}, $MemberType{$first}) }
      elsif (ref $patch->{$path} eq 'HASH') { strip_types($_, $MemberType{$first}) for values %{$patch->{$path}} }
    }
  }
}

# A: what the converter legitimately adds to a JSCalendar object that did
# not have it.  Each is the default or a value the spec makes the
# converter supply; anything else is a difference.
sub strip_added {
  my ($in, $out) = @_;
  for my $e ($in, $out) { strip_types($e, undef) }
  # version is mandatory (jscalendarbis-22 4.1.1); the reader always says "2.0"
  delete $out->{version} if !exists $in->{version} and ($out->{version} // '') eq '2.0';
  # showWithoutTime: the reader always sets it; false is the default
  delete $out->{showWithoutTime} if !exists $in->{showWithoutTime} and !$out->{showWithoutTime};
  # SEQUENCE is always written, so sequence 0 (the default) comes back
  delete $out->{sequence} if !exists $in->{sequence} and ($out->{sequence} // -1) eq '0';
  # Data::ICal writes its own PRODID when the event has no prodId; prodId
  # names the product that made the data, which here is this module
  delete $out->{prodId} if !exists $in->{prodId};
  # the reader always sets an Event's duration; "PT0S" is the default
  # (a Task's duration is a bug, TODO in part C, so dropped here too, to
  # keep the Task fixtures' other failures visible)
  delete $out->{duration} if !exists $in->{duration} and ($out->{duration} // '') eq 'PT0S';
  # an ORGANIZER converts to an owner participant too when no participant
  # is the owner (jscalendar-icalendar-29 2.3.29); the reader gives it
  # the email and (empty) name it gives every participant
  if (defined $in->{organizerCalendarAddress} and !exists $in->{participants}
      and ref $out->{participants} eq 'HASH' and keys %{$out->{participants}} == 1) {
    my ($p) = values %{$out->{participants}};
    (my $addr = $in->{organizerCalendarAddress}) =~ s/^mailto://i;
    delete $out->{participants} if $JSON->encode($p) eq $JSON->encode({
      calendarAddress => $in->{organizerCalendarAddress}, email => $addr, name => '', roles => { owner => JSON::XS::true },
    });
  }
  # an ATTACH reads back with rel "enclosure", the default (jscalendarbis-22 1.5.11)
  for my $id (keys %{ ref $out->{links} eq 'HASH' ? $out->{links} : {} }) {
    next unless ref $in->{links} eq 'HASH' and ref $in->{links}{$id} eq 'HASH';
    delete $out->{links}{$id}{rel} if !exists $in->{links}{$id}{rel} and ($out->{links}{$id}{rel} // '') eq 'enclosure';
  }
}

# is_deeply, but a number and a string differ (2 is not "2" in JSON), and
# the diagnostics list every differing path rather than the first.
sub same {
  my ($got, $expected, $name) = @_;
  my $ok = $JSON->encode([$got]) eq $JSON->encode([$expected]);
  ok($ok, $name) or diag(join "\n", 'differs at:', differences('', $expected, $got));
  return $ok;
}

sub differences {
  my ($path, $e, $g) = @_;
  if (ref $e eq 'HASH' and ref $g eq 'HASH') {
    my %keys = map { $_ => 1 } keys %$e, keys %$g;
    return map { differences("$path/$_", $e->{$_}, $g->{$_}) } sort keys %keys;
  }
  if (ref $e eq 'ARRAY' and ref $g eq 'ARRAY' and @$e == @$g) {
    return map { differences("$path/$_", $e->[$_], $g->[$_]) } 0 .. $#$e;
  }
  my ($es, $gs) = map { defined $_ ? $JSON->allow_nonref->encode($_) : '(absent)' } $e, $g;
  return $es eq $gs ? () : ("  $path: expected $es, got $gs");
}

# ---------------------------------------------------------------------------
# A. JSCalendar -> iCalendar -> JSCalendar

my %TODO_A = (
  'links-data-uri'                  => 'the reader takes an ATTACH only if it matches m{^data://}, which no data: URI does, so the link is lost',
  'locations-several'               => 'the reader reads only the first LOCATION, keyed "location"; the writer drops location keys, description and locationTypes',
  'misc-method-prodid'              => 'the writer never writes METHOD, so method is lost',
  'participants-expectreply'        => 'the reader takes RSVP=TRUE as false: it compares the value with "yes"',
  'participants-schedulesequence'   => 'the reader keeps X-SEQUENCE as a string',
  'participants-owner-chair'        => 'the writer writes one ROLE and OWNER wins over CHAIR, so chair is lost',
  'participants-chair-not-attendee' => 'the writer writes every participant but the organizer as an ATTENDEE, so roles.attendee is added',
  'participants-same-address-names' => 'ORGANIZER and ATTENDEE of one address share a CN: the last participant name wins',
  'virtual-location-description'    => 'CONFERENCE carries no description, so it is lost',
  'task-cancelled'                  => 'the writer writes no STATUS:CANCELLED for a Task, so progress "cancelled" is lost',
  'task-due'                        => 'the reader sets status from a VTODO STATUS (status is an Event property)',
  'task-no-start'                   => 'the writer dies on a Task without start (_wireDate of undef)',
);

my @fixtures;
for my $file (sort glob('testdata/roundtrip/*.json')) {
  my $all = JSON::XS::decode_json(slurp($file));
  push @fixtures, map { [$_, $all->{$_}] } sort keys %$all;
}

my @changed_input;
for my $f (@fixtures) {
  my ($name, $event) = @$f;
  local $TODO = $TODO_A{$name};
  my $snap = $JSON->encode($event);
  my @dropped;
  my @back = eval {
    my $ical = $jscal->eventsToVCalendar($event);
    push @dropped, $jscal->errors;
    push @changed_input, $name if $JSON->encode($event) ne $snap;
    my @e = $jscal->vcalendarToEvents($ical);
    push @dropped, $jscal->errors;
    @e;
  };
  if (my $err = $@) {
    fail("A $name round trip");
    diag("died: " . ($err =~ s/\n.*//sr));
    next;
  }
  if (@dropped) {
    fail("A $name round trip");
    diag("dropped: " . join('; ', map { "$_->{component} " . ($_->{uid} // '?') . ": $_->{message}" } @dropped));
    next;
  }
  my $in = $JSON->decode($snap);
  my $out = @back == 1 ? $back[0] : \@back;
  strip_added($in, $out) if @back == 1;
  same($out, $in, "A $name round trip");
}

# ---------------------------------------------------------------------------
# B. iCalendar -> JSCalendar -> iCalendar -> JSCalendar is stable

# What may legitimately differ between the first and the second
# JSCalendar: each is a default the writer leaves implicit or spells out.
sub strip_second {
  my ($first, $second) = @_;
  for my $i (0 .. $#$first) {
    my ($a, $b) = ($first->[$i], $second->[$i]);
    next unless ref $a eq 'HASH' and ref $b eq 'HASH';
    # SEQUENCE is always written, so sequence 0 (the default) appears
    delete $b->{sequence} if !exists $a->{sequence} and ($b->{sequence} // -1) eq '0';
    # an empty SUMMARY or DESCRIPTION reads as "" (the default), which is not written
    for my $key (qw(title description)) {
      delete $a->{$key} if exists $a->{$key} and $a->{$key} eq '' and !exists $b->{$key};
    }
    # RSVP=FALSE reads as expectReply false (the default), which is not written
    for my $id (keys %{ ref $a->{participants} eq 'HASH' ? $a->{participants} : {} }) {
      my $p = $a->{participants}{$id};
      next unless ref $p eq 'HASH' and exists $p->{expectReply} and !$p->{expectReply};
      my $q = ref $b->{participants} eq 'HASH' ? $b->{participants}{$id} : undef;
      delete $p->{expectReply} if ref $q eq 'HASH' and !exists $q->{expectReply};
    }
  }
}

my $VTODO_NO_DTSTART = 'the reader drops a VTODO without DTSTART (DTSTART is optional there)';
my %TODO_B = (
  'icalendar/rdate_period.ics'        => 'an RDATE;VALUE=PERIOD patch equal to the master is written as a RECURRENCE-ID instance, which reads back as no override',
  'icalendar/recurrenceoverrides.ics' => 'the same RDATE;VALUE=PERIOD loss, and an instance SEQUENCE:0 under a master without SEQUENCE is a sequence patch that the always-written SEQUENCE then hides',
  'roundtrip/ical/overrides-alarms.ics' => 'RSVP=TRUE reads as expectReply false, and ROLE=CHAIR on the organizer is lost (OWNER wins)',
  'roundtrip/ical/standalone-instance.ics' => 'an instance without SEQUENCE under a master without sequence: the always-written SEQUENCE:0 comes back as a sequence patch',
  'jscalendar-icalendar-29/figure-014.ics' => 'instances without SEQUENCE under a master without sequence: the always-written SEQUENCE:0 comes back as a sequence patch',
  'jscalendar-icalendar-29/figure-024.ics' => 'a binary ATTACH becomes a data: link, which the reader then refuses (m{^data://})',
  'jscalendar-icalendar-29/figure-042.ics' => 'the writer never writes METHOD',
  'jscalendar-icalendar-29/figure-064.ics' => 'the writer never writes METHOD',
  'jscalendar-icalendar-29/figure-069.ics' => 'an ORGANIZER that needs an ATTENDEE to carry its properties reads back with roles.attendee',
  'jscalendar-icalendar-29/figure-070.ics' => 'an ORGANIZER that needs an ATTENDEE to carry its properties reads back with roles.attendee',
  (map { ("jscalendar-icalendar-29/figure-$_.ics" => $VTODO_NO_DTSTART) } qw(019 027 047 048 049 050 053 071 082)),
);

my @ics = map { glob("testdata/$_/*.ics") } qw(. icalendar roundtrip/ical jscalendar-icalendar-29);
for my $file (sort @ics) {
  (my $name = $file) =~ s{^testdata/(?:\./)?}{};
  local $TODO = $TODO_B{$name};
  my @dropped;
  my ($first, $second) = eval {
    my @first = $jscal->vcalendarToEvents(slurp_utf8($file));
    push @dropped, $jscal->errors;
    my $snap = $JSON->encode(\@first);
    my $ical = $jscal->eventsToVCalendar(@first);
    push @dropped, $jscal->errors;
    my @second = $jscal->vcalendarToEvents($ical);
    push @dropped, $jscal->errors;
    die "eventsToVCalendar changed its input\n" if $JSON->encode(\@first) ne $snap;
    (\@first, \@second);
  };
  if (my $err = $@) {
    fail("B $name is stable");
    diag("died: " . ($err =~ s/\n.*//sr));
    next;
  }
  # a component dropped on the way is a failure, even if both sides then
  # agree (nothing read is trivially stable)
  if (@dropped) {
    fail("B $name is stable");
    diag("dropped: " . join('; ', map { "$_->{component} " . ($_->{uid} // '?') . ": $_->{message}" } @dropped));
    next;
  }
  strip_second($first, $second);
  same($second, $first, "B $name is stable");
}

# ---------------------------------------------------------------------------
# C. Known bugs that A and B do not reach

# (the writer used to stringify count, interval and byX numbers in its
# input by matching them in place; t/no-mutation.t has the details)
is_deeply(\@changed_input, [], 'C eventsToVCalendar leaves its input alone');

{
  local $TODO = 'the reader gives every VTODO a duration (PT0S without DTEND); duration is an Event property';
  my ($task) = grep { $_->{'@type'} eq 'Task' } $jscal->vcalendarToEvents(slurp_utf8('testdata/roundtrip/ical/alarm-variety.ics'));
  ok(!exists $task->{duration}, 'C a Task has no duration');
}

sub ics { join("\r\n", 'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:x', @_, 'END:VCALENDAR', '') }

{
  # jscalendar-icalendar-29 2.3.10, 4.2.1: the JSID parameter keys the
  # virtual location
  local $TODO = 'the reader keys a CONFERENCE by X-JMAP-ID or a hash, never JSID (and the writer writes X-JMAP-ID)';
  my ($e) = $jscal->vcalendarToEvents(ics('BEGIN:VEVENT', 'UID:conf@example.com', 'DTSTAMP:20250101T000000Z',
    'DTSTART:20250101T100000Z', 'CONFERENCE;VALUE=URI;JSID=v1:https://video.example.com/x', 'END:VEVENT'));
  is_deeply([keys %{$e->{virtualLocations} || {}}], ['v1'], 'C CONFERENCE JSID keys the virtual location');
}

{
  # (it used to confess in _getEventsFromVCalendar and lose every event
  # in the calendar; now the rule alone is dropped, see t/isolation.t)
  my @e = eval { $jscal->vcalendarToEvents(ics(
    'BEGIN:VEVENT', 'UID:good@example.com', 'DTSTAMP:20250101T000000Z', 'DTSTART:20250101T100000Z', 'END:VEVENT',
    'BEGIN:VEVENT', 'UID:bad@example.com', 'DTSTAMP:20250101T000000Z', 'DTSTART:20250101T100000Z',
    'RRULE:FREQ=FORTNIGHTLY', 'END:VEVENT')) };
  is_deeply([map { $_->{uid} } @e], ['bad@example.com', 'good@example.com'], 'C a bad RRULE costs no event');
  ok(!exists $e[0]{recurrenceRule}, 'C ... only the rule');
}

done_testing;

sub slurp {
  my ($file) = @_;
  open(my $fh, '<:raw', $file) or die "$file: $!";
  local $/;
  return scalar <$fh>;
}

# iCalendar is UTF-8 (RFC 5545 3.1.4); the converter takes characters
sub slurp_utf8 { Encode::decode('UTF-8', slurp(shift)) }
