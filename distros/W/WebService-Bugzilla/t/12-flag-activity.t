#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla::FlagActivity;
use WebService::Bugzilla::FlagActivity::Type;
use WebService::Bugzilla::UserDetail;

my $bz = Test::Bugzilla->new(
    base_url => 'http://bugzilla.example.com/rest',
    api_key  => 'abc',
);

subtest 'Get all flag activities' => sub {
    my $flags = $bz->flag_activity->get;
    isa_ok($flags, 'ARRAY', 'get all flag activities returns arrayref');
    isa_ok($flags->[0], 'WebService::Bugzilla::FlagActivity', 'first element is FlagActivity object');
    is($flags->[0]->bug_id, 100, 'flag activity bug_id is correct');
    is($flags->[0]->status, '?', 'flag status is correct');
    isa_ok($flags->[0]->requestee, 'WebService::Bugzilla::UserDetail', 'requestee is UserDetail');
    is($flags->[0]->requestee->name, 'req@example.com', 'requestee name is correct');
    isa_ok($flags->[0]->setter, 'WebService::Bugzilla::UserDetail', 'setter is UserDetail');
    isa_ok($flags->[0]->type, 'WebService::Bugzilla::FlagActivity::Type', 'type is FlagActivity::Type');
    is($flags->[0]->type->name, 'review', 'flag type name is review');
};

subtest 'Get flag activity by flag ID' => sub {
    my $by_flag = $bz->flag_activity->get_by_flag_id(42);
    isa_ok($by_flag->[0], 'WebService::Bugzilla::FlagActivity', 'get_by_flag_id returns FlagActivity element');
};

subtest 'Get flag activity by requestee' => sub {
    my $by_req = $bz->flag_activity->get_by_requestee('req@example.com');
    isa_ok($by_req->[0], 'WebService::Bugzilla::FlagActivity', 'get_by_requestee returns FlagActivity element');
};

subtest 'Get flag activity by setter' => sub {
    my $by_set = $bz->flag_activity->get_by_setter('set@example.com');
    isa_ok($by_set->[0], 'WebService::Bugzilla::FlagActivity', 'get_by_setter returns FlagActivity element');
};

subtest 'Get flag activity by type ID' => sub {
    my $by_tid = $bz->flag_activity->get_by_type_id(800);
    isa_ok($by_tid->[0], 'WebService::Bugzilla::FlagActivity', 'get_by_type_id returns FlagActivity element');
};

subtest 'Get flag activity by type name' => sub {
    my $by_tname = $bz->flag_activity->get_by_type_name('review');
    isa_ok($by_tname->[0], 'WebService::Bugzilla::FlagActivity', 'get_by_type_name returns FlagActivity element');
};

done_testing();
