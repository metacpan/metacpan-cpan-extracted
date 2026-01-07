#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use DateTime;

use_ok('WWW::MetaForge::ArcRaiders::Result::EventTimer');
use_ok('WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot');

subtest 'from_hashref with legacy HH:MM format' => sub {
  my $event = WWW::MetaForge::ArcRaiders::Result::EventTimer->from_hashref({
    name  => 'Cold Snap',
    map   => 'Dam',
    icon  => 'https://example.com/icon.webp',
    times => [
      { start => '04:00', end => '06:00' },
      { start => '12:00', end => '14:00' },
    ],
  });

  is($event->name, 'Cold Snap', 'name');
  is($event->map, 'Dam', 'map');
  is($event->icon, 'https://example.com/icon.webp', 'icon');
  is(scalar @{$event->times}, 2, 'times count');

  # Times are now TimeSlot objects with DateTime
  my $slot = $event->times->[0];
  isa_ok($slot, 'WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot');
  isa_ok($slot->start, 'DateTime');
  isa_ok($slot->end, 'DateTime');
  is($slot->start->hour, 4, 'first slot starts at hour 4');
  is($slot->end->hour, 6, 'first slot ends at hour 6');
};

subtest 'from_grouped with millisecond timestamps' => sub {
  # 1767556800000 = 2026-01-04 12:00:00 UTC
  # 1767564000000 = 2026-01-04 14:00:00 UTC
  my $events = [
    { name => 'Cold Snap', map => 'Dam', icon => 'https://example.com/icon.webp',
      startTime => 1767556800000, endTime => 1767564000000 },
    { name => 'Cold Snap', map => 'Dam', icon => 'https://example.com/icon.webp',
      startTime => 1767585600000, endTime => 1767592800000 },
  ];

  my $event = WWW::MetaForge::ArcRaiders::Result::EventTimer->from_grouped(
    'Cold Snap', 'Dam', $events
  );

  is($event->name, 'Cold Snap', 'name');
  is($event->map, 'Dam', 'map');
  is($event->icon, 'https://example.com/icon.webp', 'icon from first event');
  is(scalar @{$event->times}, 2, 'times count');

  my $slot = $event->times->[0];
  isa_ok($slot, 'WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot');
  isa_ok($slot->start, 'DateTime');
  isa_ok($slot->end, 'DateTime');
  is($slot->start->year, 2026, 'parsed year');
  is($slot->start->month, 1, 'parsed month');
  is($slot->start->day, 4, 'parsed day');
};

subtest 'TimeSlot from_epoch_ms' => sub {
  # 1767556800000 = 2026-01-04 20:00:00 UTC
  # 1767564000000 = 2026-01-04 22:00:00 UTC
  my $slot = WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot->from_epoch_ms(
    1767556800000, 1767564000000
  );

  isa_ok($slot, 'WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot');
  is($slot->start->year, 2026, 'start year');
  is($slot->start->hour, 20, 'start hour');
  is($slot->end->hour, 22, 'end hour');
};

subtest 'TimeSlot from_hashref with startTime/endTime' => sub {
  my $slot = WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot->from_hashref({
    startTime => 1767556800000,
    endTime   => 1767564000000,
  });

  isa_ok($slot, 'WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot');
  is($slot->start->year, 2026, 'start year');
  is($slot->start->hour, 20, 'start hour');
};

subtest 'TimeSlot contains method' => sub {
  my $slot = WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot->from_hashref({
    start => '10:00',
    end   => '12:00',
  });

  my $today = DateTime->now(time_zone => 'UTC')->truncate(to => 'day');

  my $inside = $today->clone->set(hour => 11, minute => 0);
  my $before = $today->clone->set(hour => 9, minute => 0);
  my $after = $today->clone->set(hour => 13, minute => 0);

  ok($slot->contains($inside), 'time inside slot');
  ok(!$slot->contains($before), 'time before slot');
  ok(!$slot->contains($after), 'time after slot');
};

subtest 'TimeSlot overnight handling' => sub {
  my $slot = WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot->from_hashref({
    start => '23:00',
    end   => '01:00',
  });

  # end should be next day
  ok($slot->end > $slot->start, 'overnight slot: end > start');
  is($slot->start->hour, 23, 'overnight slot starts at 23');
  is($slot->end->hour, 1, 'overnight slot ends at 1');
};

subtest 'is_active_now method' => sub {
  my $now = DateTime->now(time_zone => 'UTC');

  # Create an event that is definitely active now
  my $start_hour = ($now->hour - 1) % 24;
  my $end_hour = ($now->hour + 1) % 24;
  my $now_start = sprintf("%02d:00", $start_hour);
  my $now_end = sprintf("%02d:59", $end_hour);

  my $active_event = WWW::MetaForge::ArcRaiders::Result::EventTimer->from_hashref({
    name  => 'Test Active',
    map   => 'Test',
    times => [{ start => $now_start, end => $now_end }],
  });

  ok($active_event->is_active_now, 'event spanning current time is active');

  # Create event definitely not now (12 hours away)
  my $distant_hour = ($now->hour + 12) % 24;
  my $distant_start = sprintf("%02d:00", $distant_hour);
  my $distant_end = sprintf("%02d:01", $distant_hour);

  my $inactive_event = WWW::MetaForge::ArcRaiders::Result::EventTimer->from_hashref({
    name  => 'Test Inactive',
    map   => 'Test',
    times => [{ start => $distant_start, end => $distant_end }],
  });

  ok(!$inactive_event->is_active_now, 'event 12 hours away is inactive');
};

subtest 'next_time method' => sub {
  my $event = WWW::MetaForge::ArcRaiders::Result::EventTimer->from_hashref({
    name  => 'Test',
    map   => 'Test',
    times => [
      { start => '06:00', end => '07:00' },
      { start => '12:00', end => '13:00' },
      { start => '18:00', end => '19:00' },
    ],
  });

  my $next = $event->next_time;
  ok(defined $next, 'next_time returns a slot');
  isa_ok($next, 'WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot');
  isa_ok($next->start, 'DateTime');
  isa_ok($next->end, 'DateTime');
};

subtest 'next_time with empty times' => sub {
  my $event = WWW::MetaForge::ArcRaiders::Result::EventTimer->from_hashref({
    name  => 'Empty',
    map   => 'Test',
    times => [],
  });

  my $next = $event->next_time;
  ok(!defined $next, 'next_time returns undef for empty times');
};

subtest 'current_slot method' => sub {
  my $now = DateTime->now(time_zone => 'UTC');

  my $start_hour = ($now->hour - 1) % 24;
  my $end_hour = ($now->hour + 1) % 24;
  my $now_start = sprintf("%02d:00", $start_hour);
  my $now_end = sprintf("%02d:59", $end_hour);

  my $event = WWW::MetaForge::ArcRaiders::Result::EventTimer->from_hashref({
    name  => 'Test',
    map   => 'Test',
    times => [{ start => $now_start, end => $now_end }],
  });

  my $slot = $event->current_slot;
  ok(defined $slot, 'current_slot returns slot when active');
  isa_ok($slot, 'WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot');
};

subtest 'defaults' => sub {
  my $event = WWW::MetaForge::ArcRaiders::Result::EventTimer->from_hashref({
    name => 'Minimal',
    map  => 'Test',
  });

  is(ref $event->times, 'ARRAY', 'times defaults to array');
  is(scalar @{$event->times}, 0, 'times is empty');
  ok(!defined $event->icon, 'icon defaults to undef');
};

done_testing;
