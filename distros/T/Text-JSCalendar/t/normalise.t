#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::PP ();
use Text::JSCalendar;

# NormaliseEvent / CompareEvents: defaults dropped, everything else kept.

my $true  = JSON::PP::true();
my $false = JSON::PP::false();
my $J = 'Text::JSCalendar';

sub norm { $J->NormaliseEvent(@_) }

my $base = {
  '@type' => 'Event', uid => 'n@example.com', updated => '2025-01-01T00:00:00Z',
  start => '2025-01-01T10:00:00', duration => 'PT1H',
};

# defaults (jscalendarbis-22) are dropped
is_deeply(norm({ %$base,
  status => 'confirmed', descriptionContentType => 'text/plain', freeBusyStatus => 'busy',
  privacy => 'public', priority => 0, sequence => 0, title => '', description => '',
  showWithoutTime => $false }),
  norm($base), 'top-level defaults dropped');
is(norm({ %$base, duration => 'PT0S' })->{duration}, undef, 'duration PT0S is the default');
is(norm({ %$base, status => 'tentative' })->{status}, 'tentative', 'a non-default status is kept');
ok($J->CompareEvents({ %$base, status => 'confirmed' }, $base), 'status confirmed == absent');
ok(!$J->CompareEvents({ %$base, status => 'cancelled' }, $base), 'status cancelled != absent');

# @type: kept on the Event/Task, dropped where the position implies it
is(norm($base)->{'@type'}, 'Event', 'Event @type kept');
ok(!$J->CompareEvents($base, { %$base, '@type' => 'Task' }), 'Event != Task');
is_deeply(norm({ %$base, locations => { l1 => { '@type' => 'Location', name => 'x' } } })->{locations},
  { l1 => { name => 'x' } }, 'implied Location @type dropped');
is_deeply(norm({ %$base, recurrenceRule => { '@type' => 'RecurrenceRule', frequency => 'daily',
    interval => 1, byDay => [{ '@type' => 'NDay', day => 'mo' }] } })->{recurrenceRule},
  { frequency => 'daily', byDay => [{ day => 'mo' }] }, 'RecurrenceRule, NDay @type and interval 1 dropped');

# unknown keys are kept
is(norm({ %$base, 'example.com:foo' => 'bar' })->{'example.com:foo'}, 'bar', 'unknown top-level key kept');
is(norm({ %$base, locations => { l1 => { name => 'x', description => 'y' } } })->{locations}{l1}{description},
  'y', 'unknown Location key kept');

# alert triggers keep their contents
my $alert = sub { +{ %$base, alerts => { a1 => { '@type' => 'Alert', trigger => shift } } } };
is_deeply(norm($alert->({ '@type' => 'OffsetTrigger', offset => '-PT15M', relativeTo => 'start' }))->{alerts},
  { a1 => { trigger => { offset => '-PT15M' } } }, 'OffsetTrigger: defaults and implied @type dropped');
ok(!$J->CompareEvents($alert->({ offset => '-PT15M' }), $alert->({ offset => '-PT5M' })),
  'two different offsets are not equal');
ok(!$J->CompareEvents($alert->({ offset => '-PT15M' }), $alert->({ offset => '-PT15M', relativeTo => 'end' })),
  'relativeTo end is not start');
is_deeply(norm($alert->({ '@type' => 'AbsoluteTrigger', when => '2025-01-01T09:00:00Z' }))->{alerts}{a1}{trigger},
  { '@type' => 'AbsoluteTrigger', when => '2025-01-01T09:00:00Z' }, 'AbsoluteTrigger kept whole');
ok(!$J->CompareEvents($alert->({ '@type' => 'AbsoluteTrigger', when => '2025-01-01T09:00:00Z' }),
                      $alert->({ '@type' => 'AbsoluteTrigger', when => '2025-01-01T08:00:00Z' })),
  'two absolute triggers differ');

# override patches keep their contents
my $over = sub { +{ %$base, recurrenceRule => { frequency => 'daily' }, recurrenceOverrides => { '2025-01-02T10:00:00' => shift } } };
is_deeply(norm($over->({ excluded => $true }))->{recurrenceOverrides},
  { '2025-01-02T10:00:00' => { excluded => $true } }, 'excluded kept');
ok(!$J->CompareEvents($over->({ excluded => $true }), $over->({})), 'excluded != RDATE-style {}');
is_deeply(norm($over->({}))->{recurrenceOverrides}, { '2025-01-02T10:00:00' => {} }, 'empty patch kept');
is_deeply(norm($over->({ status => 'confirmed', title => '' }))->{recurrenceOverrides}{'2025-01-02T10:00:00'},
  { status => 'confirmed', title => '' }, 'a patch setting a default keeps it');
is_deeply(norm($over->({ 'participants/p1' => { '@type' => 'Participant', name => 'A', expectReply => $false,
    roles => { attendee => $true } } }))->{recurrenceOverrides}{'2025-01-02T10:00:00'},
  { 'participants/p1' => { name => 'A', roles => { attendee => $true } } }, 'a patched participant is normalised');
is_deeply(norm($over->({ 'participants/p1/participationStatus' => 'needs-action', 'alerts/a1/trigger' =>
    { '@type' => 'OffsetTrigger', offset => '-PT1M', relativeTo => 'start' }, 'example.com:x/y' => [1] }))
    ->{recurrenceOverrides}{'2025-01-02T10:00:00'},
  { 'participants/p1/participationStatus' => 'needs-action', 'alerts/a1/trigger' => { offset => '-PT1M' },
    'example.com:x/y' => [1] }, 'patched trigger normalised, scalar and unknown paths kept');
is_deeply(norm($over->({ locations => {} }))->{recurrenceOverrides}{'2025-01-02T10:00:00'},
  { locations => {} }, 'an empty map in a patch is kept');
is_deeply(norm($over->({ participants => { p1 => { '@type' => 'Participant', kind => 'individual' } } }))
    ->{recurrenceOverrides}{'2025-01-02T10:00:00'},
  { participants => { p1 => { kind => 'individual' } } }, 'a patched whole map is normalised member by member');

# the input is not changed
my $in = $alert->({ '@type' => 'OffsetTrigger', offset => '-PT15M' });
norm($in);
is($in->{alerts}{a1}{trigger}{'@type'}, 'OffsetTrigger', 'input untouched');

done_testing;
