#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use WebService::HabitRPG::Task;
use JSON::Any;
use DateTime;

sub active_repeat_for_today {
    my $today = DateTime->now;
    $today->set_time_zone('local');

    my $day_of_week = $today->day_of_week;

    my @repeat_map = WebService::HabitRPG::Task::HRPG_REPEAT_MAP;

    my $repeat = { map { $_ => JSON::Any::false } @repeat_map };

    $repeat->{$repeat_map[$day_of_week - 1]} = JSON::Any::true;

    return $repeat;
}

sub inactive_repeat_for_today {
    return { map { $_ => JSON::Any::false } WebService::HabitRPG::Task::HRPG_REPEAT_MAP };
}

my %template = (
    'id' => 'a670fc50-4e04-4b0f-9583-e4ee55fced02',
    'text' => 'Test Task',
    'type' => 'daily',
    'frequency' => '',
    'streak' => 0,
    'startDate' => DateTime->today->iso8601(),
    'value' => 1,
    'repeat' => {},
);

my $non_daily = WebService::HabitRPG::Task->new({
    %template,

    'type' => 'habit',
});

my $weekly_active = WebService::HabitRPG::Task->new({
    %template,

    'frequency' => 'weekly',
    'repeat' => active_repeat_for_today(),
});

my $weekly_inactive = WebService::HabitRPG::Task->new({
    %template,

    'frequency' => 'weekly',
    'repeat' => inactive_repeat_for_today(),
});

my $daily_active = WebService::HabitRPG::Task->new({
    %template,

    'frequency' => 'daily',
    'everyX' => 37, # arbitrary number greater than days in a month and indivisible by weeks
    'startDate' => DateTime->today->subtract(days => 37 * 2)->iso8601(),
});

my $daily_inactive = WebService::HabitRPG::Task->new({
    %template,

    'frequency' => 'daily',
    'everyX' => 37, # arbitrary number greater than days in a month and indivisible by weeks
    'startDate' => DateTime->today->subtract(days => 1)->iso8601(),
});

ok $non_daily->active_today, 'Tasks not of type daily are always active_today';
ok $weekly_active->active_today, 'Daily tasks of frequency weekly are active_today if the current day of the week is in their repeat map';
ok !$weekly_inactive->active_today, 'Daily tasks of frequency weekly are active_today if the current day of the week is in their repeat map';
ok $daily_active->active_today, 'Daily tasks of frequency daily are active_today if the number of days since their start date is divisible by their everyX';
ok !$daily_inactive->active_today, 'Daily tasks of frequency daily are active_today if the number of days since their start date is divisible by their everyX';

done_testing;
