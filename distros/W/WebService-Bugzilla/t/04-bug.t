#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla::Bug;
use WebService::Bugzilla::Bug::History;
use WebService::Bugzilla::Bug::History::Change;

my $bz = Test::Bugzilla->new(
    base_url => 'http://bugzilla.example.com/rest',
    api_key  => 'abc',
);

subtest 'get() returns a Bug object' => sub {
    my $bug = $bz->bug->get(123);
    isa_ok($bug, 'WebService::Bugzilla::Bug', 'returned Bug object');
    is($bug->id, 123, 'bug id');
    is($bug->summary, 'Example', 'bug summary');
};

subtest 'search() returns array of Bug objects' => sub {
    my $bugs = $bz->bug->search(product => 'Test');
    isa_ok($bugs, 'ARRAY', 'search returns arrayref');
    is(scalar @{$bugs}, 1, 'one bug returned');
    isa_ok($bugs->[0], 'WebService::Bugzilla::Bug', 'element is Bug object');
};

subtest 'create() returns a new Bug object' => sub {
    my $new_bug = $bz->bug->create(summary => 'new', product => 'Test');
    isa_ok($new_bug, 'WebService::Bugzilla::Bug', 'created Bug object');
    is($new_bug->id, 456, 'created bug id');
};

subtest 'update() via class method' => sub {
    my $updated_bug = $bz->bug->update(123, status => 'ASSIGNED');
    isa_ok($updated_bug, 'WebService::Bugzilla::Bug', 'updated Bug object (class method)');
    is($updated_bug->id, 123, 'updated bug id (class)');
};

subtest 'update() via instance method' => sub {
    my $bug = $bz->bug->get(123);
    my $inst_updated_bug = $bug->update(status => 'RESOLVED');
    isa_ok($inst_updated_bug, 'WebService::Bugzilla::Bug', 'updated Bug object (instance method)');
};

subtest 'history() returns array of History objects' => sub {
    my $history = $bz->bug->history(123);
    isa_ok($history, 'ARRAY', 'history is arrayref');
    is(scalar @{$history}, 1, 'one history entry');
    my $entry = $history->[0];
    isa_ok($entry, 'WebService::Bugzilla::Bug::History', 'history entry object');
    is($entry->who, 'dev@example.com', 'history who');
    isa_ok($entry->changes, 'ARRAY', 'changes is arrayref');
    is(scalar @{ $entry->changes }, 2, 'two changes in entry');
};

subtest 'history() includes Change objects with correct data' => sub {
    my $history = $bz->bug->history(123);
    my $entry = $history->[0];
    my $change = $entry->changes->[0];
    isa_ok($change, 'WebService::Bugzilla::Bug::History::Change', 'Change object');
    is($change->field_name, 'status', 'change field_name');
    is($change->removed, 'NEW', 'change removed value');
    is($change->added, 'ASSIGNED', 'change added value');
    ok(!$change->has_attachment_id, 'first change has no attachment_id');
    my $attach_change = $entry->changes->[1];
    ok($attach_change->has_attachment_id, 'second change has attachment_id');
    is($attach_change->attachment_id, 5, 'attachment id on second change');
};

subtest 'history() via instance method' => sub {
    my $bug = $bz->bug->get(123);
    my $inst_history = $bug->history;
    isa_ok($inst_history, 'ARRAY', 'instance history is arrayref');
};

subtest 'possible_duplicates() returns array of Bug objects' => sub {
    my $dupes = $bz->bug->possible_duplicates(123);
    isa_ok($dupes, 'ARRAY', 'possible duplicates returns arrayref');
    isa_ok($dupes->[0], 'WebService::Bugzilla::Bug', 'duplicate is Bug object');
    is($dupes->[0]->id, 999, 'duplicate bug id');
};

subtest 'possible_duplicates() via instance method' => sub {
    my $bug = $bz->bug->get(123);
    my $inst_dupes = $bug->possible_duplicates;
    isa_ok($inst_dupes, 'ARRAY');
};

done_testing();
