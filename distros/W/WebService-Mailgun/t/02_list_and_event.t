use strict;
use Test::More 0.98;
use Test::Exception;
use WebService::Mailgun;
use JSON;
use String::Random;

my $mailgun = WebService::Mailgun->new(
    api_key => 'key-389807c554fdfe0a7757adf0650f7768',
    domain  => 'sandbox56435abd76e84fa6b03de82540e11271.mailgun.org',
    RaiseError => 1,
);

my $listname = String::Random->new->randregex('[a-z0-9]{16}');
note "listname: $listname";

sub list_address () {
    $listname . '@' . $mailgun->domain;
}

subtest 'add mailing list' => sub {
    ok my $res = $mailgun->add_list({
        address => list_address,
        name    => 'list1',
        description => 'list',
        access_level => 'everyone',
    });
    my ($lists,undef) = $mailgun->lists();
    ok scalar(@$lists) >= 1, 'get lists';
    my $data = $mailgun->list(list_address);
    delete $data->{created_at};
    is_deeply $data, {
        address => list_address,
        name    => 'list1',
        description => 'list',
        access_level => 'everyone',
        members_count => 0,
        reply_preference => 'list',
    }, 'check list detail';
};

subtest 'update mailing list' => sub {
    ok my $res = $mailgun->update_list(list_address() => {
        name    => 'list1+fix',
        description => 'list+fix',
        access_level => 'members',
    });
    my $data = $mailgun->list(list_address);
    delete $data->{created_at};
    is_deeply $data, {
        address => list_address,
        name    => 'list1+fix',
        description => 'list+fix',
        access_level => 'members',
        members_count => 0,
        reply_preference => 'list',
    }, 'check list detail';
};

subtest 'add mailing list member' => sub {
    ok my $res = $mailgun->add_list_member(list_address() => {
        address => 'user1@example.com',
        name    => 'user1',
        vars    => '{"age": 34}',
    });
    ok my $res2 = $mailgun->add_list_members(list_address() => {
        members => encode_json [qw/user2@example.com user3@example.com/],
    });

    my ($members, $undef) = $mailgun->list_members(list_address);
    ok $members;
    ok scalar(@$members) == 3, 'list members';

    my $member = $mailgun->list_member(list_address, 'user1@example.com');
    ok delete $member->{subscribed};
    is_deeply $member, {
        address => 'user1@example.com',
        name    => 'user1',
        vars    => { age => 34 },
    };
};

subtest 'update list member' => sub {
    ok my $res = $mailgun->update_list_member(list_address, 'user1@example.com' => {
        name    => 'user1+fix',
        vars    => '{"age": 35, "gender": "male"}',
        subscribed => 'no',
    });
    my $member = $mailgun->list_member(list_address, 'user1@example.com');
    ok ! delete $member->{subscribed};
    is_deeply $member, {
        address => 'user1@example.com',
        name    => 'user1+fix',
        vars    => { age => 35, gender => 'male' },
    };
};

subtest 'delete list member' => sub {
    ok my $res = $mailgun->delete_list_member(list_address, 'user1@example.com');
    my ($members, undef) = $mailgun->list_members(list_address);
    ok scalar(@$members) == 2, 'list members';
};

subtest 'delete mailing list' => sub {
    ok my $res = $mailgun->delete_list(list_address);
    dies_ok { my $list = $mailgun->list(list_address); }, '', 'delete list';
};

# eventデータが一定期間で消えてしまうのでコメントアウト
=pod
subtest 'get events' => sub {
    my ($res, undef) = $mailgun->event({
        event => 'list_uploaded',
    });
    ok $res;
    cmp_ok( scalar(@$res), ">=", 1, 'event results found' );
    note explain $res;
};
=cut

done_testing;

