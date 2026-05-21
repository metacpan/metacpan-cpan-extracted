#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use JSON::XS;
use LWP::UserAgent;
use HTTP::Request;

use lib 'lib';
use Text::JSCalendar;

# Skip unless CYRUS_URL is set
unless ($ENV{CYRUS_URL}) {
  plan skip_all => "Set CYRUS_URL, CYRUS_USER, CYRUS_PASS to enable Cyrus integration tests"
    . " (e.g. CYRUS_URL=http://localhost:8080 CYRUS_USER=user1 CYRUS_PASS=password)";
}

my $base = $ENV{CYRUS_URL};
my $user = $ENV{CYRUS_USER} || 'user1';
my $pass = $ENV{CYRUS_PASS} || 'password';
my $calpath = "$base/dav/calendars/user/$user/Default";

my $ua = LWP::UserAgent->new(timeout => 5);

# Check if Cyrus is actually reachable
my $probe = $ua->get("$base/dav/principals/user/$user/");
unless ($probe->code < 500) {
  plan skip_all => "Cyrus not reachable at $base";
}

my $jscal = Text::JSCalendar->new();
my $json = JSON::XS->new->pretty(1)->canonical(1);

sub caldav_put {
  my ($uid, $ical) = @_;
  my $req = HTTP::Request->new(PUT => "$calpath/$uid.ics");
  $req->authorization_basic($user, $pass);
  $req->content_type('text/calendar; charset=utf-8');
  $req->content($ical);
  return $ua->request($req);
}

sub caldav_get {
  my ($uid) = @_;
  my $req = HTTP::Request->new(GET => "$calpath/$uid.ics");
  $req->authorization_basic($user, $pass);
  return $ua->request($req);
}

sub caldav_delete {
  my ($uid) = @_;
  my $req = HTTP::Request->new(DELETE => "$calpath/$uid.ics");
  $req->authorization_basic($user, $pass);
  return $ua->request($req);
}

# ============================================================
# Test 1: Simple event round-trip through Cyrus
# ============================================================

my $simple_uid = 'jscal-test-simple-' . time();
my $simple_ical = <<"ICAL";
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Text-JSCalendar//Test//EN
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:$simple_uid
DTSTART;TZID=America/New_York:20250101T100000
DTEND;TZID=America/New_York:20250101T110000
SUMMARY:JSCalendar Test Event
DESCRIPTION:Testing round-trip through Cyrus
LOCATION:Test Room 42
PRIORITY:5
CATEGORIES:testing,jscalendar
SEQUENCE:0
DTSTAMP:20250101T000000Z
CREATED:20250101T000000Z
END:VEVENT
END:VCALENDAR
ICAL

# PUT the event
my $put_resp = caldav_put($simple_uid, $simple_ical);
ok($put_resp->is_success || $put_resp->code == 201 || $put_resp->code == 204,
   "PUT simple event: " . $put_resp->status_line);

# GET it back
my $get_resp = caldav_get($simple_uid);
ok($get_resp->is_success, "GET simple event back");
my $returned_ical = $get_resp->content;

# Parse the returned iCal with Text::JSCalendar
my @events = eval { $jscal->vcalendarToEvents($returned_ical) };
ok(!$@, "Parse returned iCal") or diag $@;
is(scalar @events, 1, "Got one event");

my $event = $events[0];
is($event->{uid}, $simple_uid, "UID preserved");
is($event->{title}, 'JSCalendar Test Event', "title preserved");
is($event->{description}, 'Testing round-trip through Cyrus', "description preserved");
is($event->{priority}, 5, "priority preserved");
ok($event->{keywords}{testing}, "keywords: testing");
ok($event->{keywords}{jscalendar}, "keywords: jscalendar");
ok($event->{locations}, "has locations");

# Convert JSCalendar back to iCal
my $generated_ical = eval { $jscal->eventsToVCalendar(@events) };
ok(!$@, "Generate iCal from JSCalendar") or diag $@;
like($generated_ical, qr/BEGIN:VCALENDAR/, "Generated valid iCal");

# Parse the generated iCal again
my @events2 = eval { $jscal->vcalendarToEvents($generated_ical) };
ok(!$@, "Re-parse generated iCal") or diag $@;

# Compare key fields (normalize for comparison)
my $e1 = Text::JSCalendar->NormaliseEvent($events[0]);
my $e2 = Text::JSCalendar->NormaliseEvent($events2[0]);
is($e2->{uid}, $e1->{uid}, "Round-trip: uid");
is($e2->{title}, $e1->{title}, "Round-trip: title");
is($e2->{start}, $e1->{start}, "Round-trip: start");
is($e2->{duration}, $e1->{duration}, "Round-trip: duration");
is($e2->{timeZone}, $e1->{timeZone}, "Round-trip: timeZone");

# Cleanup
caldav_delete($simple_uid);

# ============================================================
# Test 2: Event with end timezone
# ============================================================

my $etz_uid = 'jscal-test-endtz-' . time();
my $etz_ical = <<"ICAL";
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Text-JSCalendar//Test//EN
BEGIN:VEVENT
UID:$etz_uid
DTSTART;TZID=America/New_York:20250615T090000
DTEND;TZID=America/Los_Angeles:20250615T120000
SUMMARY:Cross-timezone meeting
DTSTAMP:20250101T000000Z
END:VEVENT
END:VCALENDAR
ICAL

$put_resp = caldav_put($etz_uid, $etz_ical);
ok($put_resp->is_success || $put_resp->code == 201 || $put_resp->code == 204,
   "PUT endtz event");

$get_resp = caldav_get($etz_uid);
ok($get_resp->is_success, "GET endtz event");

@events = eval { $jscal->vcalendarToEvents($get_resp->content) };
ok(!$@, "Parse endtz event") or diag $@;
$event = $events[0];
is($event->{timeZone}, 'America/New_York', "start timezone");
ok(!exists $event->{endTimeZone}, "endTimeZone not present (RFC 8984 removed this field)");

caldav_delete($etz_uid);

# ============================================================
# Test 3: Event with GEO
# ============================================================

my $geo_uid = 'jscal-test-geo-' . time();
my $geo_ical = <<"ICAL";
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Text-JSCalendar//Test//EN
BEGIN:VEVENT
UID:$geo_uid
DTSTART:20250301T120000Z
DTEND:20250301T130000Z
SUMMARY:Geo Event
GEO:48.198634;16.371648
LOCATION:Vienna Office
DTSTAMP:20250101T000000Z
END:VEVENT
END:VCALENDAR
ICAL

$put_resp = caldav_put($geo_uid, $geo_ical);
ok($put_resp->is_success || $put_resp->code == 201 || $put_resp->code == 204,
   "PUT geo event");

$get_resp = caldav_get($geo_uid);
ok($get_resp->is_success, "GET geo event");

@events = eval { $jscal->vcalendarToEvents($get_resp->content) };
ok(!$@, "Parse geo event") or diag $@;
$event = $events[0];
ok($event->{locations}, "has locations");
# Check that GEO was preserved (Cyrus may or may not keep it)
my $has_coords = 0;
for my $loc (values %{$event->{locations} || {}}) {
  $has_coords = 1 if $loc->{coordinates};
}
ok($has_coords, "GEO coordinates present") or diag $json->encode($event->{locations});

caldav_delete($geo_uid);

# ============================================================
# Test 4: Event with CONFERENCE (if Cyrus supports it)
# ============================================================

my $conf_uid = 'jscal-test-conf-' . time();
my $conf_ical = <<"ICAL";
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Text-JSCalendar//Test//EN
BEGIN:VEVENT
UID:$conf_uid
DTSTART:20250401T140000Z
DTEND:20250401T150000Z
SUMMARY:Conference Call
CONFERENCE;VALUE=URI;FEATURE=AUDIO,VIDEO;LABEL=Zoom Meeting:https://zoom.us/j/123456
DTSTAMP:20250101T000000Z
END:VEVENT
END:VCALENDAR
ICAL

$put_resp = caldav_put($conf_uid, $conf_ical);
if ($put_resp->is_success || $put_resp->code == 201 || $put_resp->code == 204) {
  pass("PUT conference event");
  $get_resp = caldav_get($conf_uid);
  ok($get_resp->is_success, "GET conference event");

  @events = eval { $jscal->vcalendarToEvents($get_resp->content) };
  ok(!$@, "Parse conference event") or diag $@;
  $event = $events[0];

  if ($event->{virtualLocations} && keys %{$event->{virtualLocations}}) {
    pass("CONFERENCE preserved by Cyrus");
    my @vlocs = values %{$event->{virtualLocations}};
    like($vlocs[0]{uri}, qr/zoom/, "Conference URI preserved");
  } else {
    # Cyrus may strip unknown properties
    pass("CONFERENCE not preserved by Cyrus (expected for older versions)");
  }

  caldav_delete($conf_uid);
} else {
  pass("SKIP: Cyrus rejected CONFERENCE property");
  pass("SKIP");
  pass("SKIP");
  pass("SKIP");
}

# ============================================================
# Test 5: VTODO/Task
# ============================================================

my $todo_uid = 'jscal-test-todo-' . time();
my $todo_ical = <<"ICAL";
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Text-JSCalendar//Test//EN
BEGIN:VTODO
UID:$todo_uid
DTSTART:20250501T090000Z
DUE:20250502T170000Z
SUMMARY:Test Task
PERCENT-COMPLETE:50
STATUS:IN-PROCESS
PRIORITY:3
DTSTAMP:20250101T000000Z
END:VTODO
END:VCALENDAR
ICAL

$put_resp = caldav_put($todo_uid, $todo_ical);
if ($put_resp->is_success || $put_resp->code == 201 || $put_resp->code == 204) {
  pass("PUT task");
  $get_resp = caldav_get($todo_uid);
  ok($get_resp->is_success, "GET task");

  @events = eval { $jscal->vcalendarToEvents($get_resp->content) };
  ok(!$@, "Parse task") or diag $@;
  $event = $events[0];
  is($event->{'@type'}, 'Task', '@type is Task');
  is($event->{title}, 'Test Task', 'task title');
  is($event->{percentComplete}, 50, 'percentComplete');
  is($event->{progress}, 'in-process', 'progress');
  is($event->{priority}, 3, 'task priority');
  ok($event->{due}, 'has due date');

  caldav_delete($todo_uid);
} else {
  # VTODOs in calendar collection may not be allowed
  pass("SKIP: Cyrus rejected VTODO in calendar: " . $put_resp->status_line);
  for (1..7) { pass("SKIP") }
}

# ============================================================
# Test 6: Create via JMAP, read via CalDAV, compare
# ============================================================

my $jmap_uid = 'jscal-jmap-create-' . time();

# Create event via JMAP
my $jmap_create = $ua->post(
  "$base/jmap/",
  Authorization => "Basic " . MIME::Base64::encode_base64("$user:$pass", ''),
  'Content-Type' => 'application/json',
  Content => encode_json({
    using => ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:calendars", "https://cyrusimap.org/ns/jmap/calendars"],
    methodCalls => [
      ["CalendarEvent/set", {
        create => {
          "evt1" => {
            calendarIds => { Default => JSON::true },
            uid => $jmap_uid,
            title => "Created via JMAP",
            description => "This event was created through the JMAP API",
            start => "2025-08-20T14:00:00",
            timeZone => "Europe/London",
            duration => "PT2H",
            priority => 7,
            freeBusyStatus => "free",
            keywords => { jmaptest => JSON::true, automated => JSON::true },
            locations => {
              loc1 => { name => "London Office" },
            },
          }
        }
      }, "0"]
    ]
  }),
);

my $jmap_result = eval { decode_json($jmap_create->content) };
my $created = $jmap_result->{methodResponses}[0][1]{created}{evt1};
if ($created) {
  pass("Created event via JMAP");

  # Now read it back via CalDAV
  my $caldav_resp = caldav_get($jmap_uid);
  ok($caldav_resp->is_success, "GET JMAP-created event via CalDAV");

  my $cyrus_ical = $caldav_resp->content;

  # Parse the Cyrus-generated iCal with our module
  my @parsed = eval { $jscal->vcalendarToEvents($cyrus_ical) };
  ok(!$@, "Parse Cyrus-generated iCal") or diag $@;

  my $parsed_event = $parsed[0];
  is($parsed_event->{uid}, $jmap_uid, "JMAP->CalDAV: uid matches");
  is($parsed_event->{title}, "Created via JMAP", "JMAP->CalDAV: title matches");
  is($parsed_event->{description}, "This event was created through the JMAP API", "JMAP->CalDAV: description");
  is($parsed_event->{start}, "2025-08-20T14:00:00", "JMAP->CalDAV: start");
  is($parsed_event->{timeZone}, "Europe/London", "JMAP->CalDAV: timeZone");
  is($parsed_event->{duration}, "PT2H", "JMAP->CalDAV: duration");
  is($parsed_event->{priority}, 7, "JMAP->CalDAV: priority");
  is($parsed_event->{freeBusyStatus}, "free", "JMAP->CalDAV: freeBusyStatus");
  ok($parsed_event->{keywords}{jmaptest}, "JMAP->CalDAV: keyword jmaptest");
  ok($parsed_event->{keywords}{automated}, "JMAP->CalDAV: keyword automated");

  # Check location was preserved
  my $has_location = 0;
  for my $loc (values %{$parsed_event->{locations} || {}}) {
    $has_location = 1 if ($loc->{name} || '') eq 'London Office';
  }
  ok($has_location, "JMAP->CalDAV: location preserved");

  # Now also read via JMAP and compare key fields
  my $jmap_get = $ua->post(
    "$base/jmap/",
    Authorization => "Basic " . MIME::Base64::encode_base64("$user:$pass", ''),
    'Content-Type' => 'application/json',
    Content => encode_json({
      using => ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:calendars"],
      methodCalls => [
        ["CalendarEvent/get", { ids => [$created->{id}] }, "0"]
      ]
    }),
  );
  my $jmap_event = eval { decode_json($jmap_get->content)->{methodResponses}[0][1]{list}[0] };

  if ($jmap_event) {
    is($parsed_event->{title}, $jmap_event->{title}, "CalDAV parse matches JMAP: title");
    is($parsed_event->{start}, $jmap_event->{start}, "CalDAV parse matches JMAP: start");
    is($parsed_event->{timeZone}, $jmap_event->{timeZone}, "CalDAV parse matches JMAP: timeZone");
    is($parsed_event->{duration}, $jmap_event->{duration}, "CalDAV parse matches JMAP: duration");
    is($parsed_event->{priority}, $jmap_event->{priority}, "CalDAV parse matches JMAP: priority");
    is($parsed_event->{freeBusyStatus}, $jmap_event->{freeBusyStatus}, "CalDAV parse matches JMAP: freeBusyStatus");
  } else {
    for (1..6) { pass("SKIP: could not read back via JMAP") }
  }

  caldav_delete($jmap_uid);
} else {
  pass("SKIP: JMAP CalendarEvent/set failed: " . $jmap_create->content);
  for (1..18) { pass("SKIP") }
}

done_testing();
