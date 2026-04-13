#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla::Reminder;

my $bz = Test::Bugzilla->new(
    base_url => 'http://bugzilla.example.com/rest',
    api_key  => 'abc',
);

subtest 'Get reminder' => sub {
    my $reminder = $bz->reminder->get(123);
    isa_ok($reminder, 'WebService::Bugzilla::Reminder', 'returned Reminder object');
    is($reminder->id, 123, 'reminder id');
    is($reminder->bug_id, 456, 'reminder bug_id');
    is($reminder->note, 'Test reminder', 'reminder note');
    is($reminder->reminder_ts, '2024-06-08', 'reminder timestamp');
    ok(!$reminder->sent, 'reminder not sent');
};

subtest 'Search reminders' => sub {
    my $reminders = $bz->reminder->search;
    isa_ok($reminders, 'ARRAY', 'search returns arrayref');
    is(scalar @{$reminders}, 1, 'one reminder returned');
    isa_ok($reminders->[0], 'WebService::Bugzilla::Reminder', 'element is Reminder object');
};

subtest 'Create reminder' => sub {
    my $new_reminder = $bz->reminder->create(bug_id => 789, note => 'New', reminder_ts => '2024-07-01');
    isa_ok($new_reminder, 'WebService::Bugzilla::Reminder', 'created Reminder object');
    is($new_reminder->id, 999, 'created reminder id');
    is($new_reminder->bug_id, 789, 'created reminder bug_id');
};

subtest 'Remove reminder' => sub {
    my $reminder = $bz->reminder->get(123);
    ok($reminder->remove, 'reminder->remove returns success');
};

done_testing();
