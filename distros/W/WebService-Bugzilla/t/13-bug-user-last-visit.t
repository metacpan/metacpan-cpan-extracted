#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla::BugUserLastVisit;

my $bz = Test::Bugzilla->new(
    base_url => 'http://bugzilla.example.com/rest',
    api_key  => 'abc',
);

subtest 'Get all bug user last visits' => sub {
    my $visits = $bz->bug_user_last_visit->get;
    isa_ok($visits, 'ARRAY', 'get all visits returns arrayref');
    isa_ok($visits->[0], 'WebService::Bugzilla::BugUserLastVisit', 'first element is BugUserLastVisit');
    is($visits->[0]->bug_id, 123, 'visit bug_id is correct');
};

subtest 'Get bug user last visit by bug ID' => sub {
    my $visit = $bz->bug_user_last_visit->get_bug(123);
    isa_ok($visit, 'WebService::Bugzilla::BugUserLastVisit', 'get_bug returns BugUserLastVisit object');
    is($visit->bug_id, 123, 'visit bug_id is correct');
};

subtest 'Update bug user last visit' => sub {
    my $updated_visit = $bz->bug_user_last_visit->update(123);
    isa_ok($updated_visit, 'WebService::Bugzilla::BugUserLastVisit', 'update returns BugUserLastVisit object');
};

subtest 'Update bug user last visit via instance method' => sub {
    my $visit = $bz->bug_user_last_visit->get_bug(123);
    my $inst_updated_visit = $visit->update;
    isa_ok($inst_updated_visit, 'WebService::Bugzilla::BugUserLastVisit', 'instance update returns BugUserLastVisit object');
};

subtest 'Update multiple bug user last visits' => sub {
    my $multi = $bz->bug_user_last_visit->update_bugs(123, 456);
    isa_ok($multi, 'ARRAY', 'update_bugs returns arrayref');
    isa_ok($multi->[0], 'WebService::Bugzilla::BugUserLastVisit', 'first element is BugUserLastVisit');
};

done_testing();
