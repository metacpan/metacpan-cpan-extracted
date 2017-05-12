use strict;
use warnings;
use Test::Most;

use WebService::NationBuilder;
use Log::Any::Adapter;
use Log::Dispatch;

my @ARGS = qw(NB_ACCESS_TOKEN NB_SUBDOMAIN);
for (@ARGS) {plan skip_all => "$_ not in ENV" unless defined $ENV{$_}};
my %params = map { (lc substr $_, 3) => $ENV{$_} } @ARGS;

sub _enable_logging {
    my $log = Log::Dispatch->new(
        outputs => [
            [
                'Screen',
                min_level => 'debug',
                stderr    => 1,
                newline   => 1,
            ]
        ],
    );

    Log::Any::Adapter->set(
        'Dispatch',
        dispatcher => $log,
    );
}

my $nb = WebService::NationBuilder->new(%params);
my $page_txt = 'paginating with %s page(s)';
my @page_totals = (1, 10, 100, 1000);
my $max_id = 10000;
my $test_tag = 'test_tag';
my $test_user = {
    first_name  => 'firstname',
    last_name   => 'lastname',
    email       => 'test@gmail.com',
    phone       => '415-123-4567',
    mobile      => '555-123-4567',
};

#_enable_logging;

subtest 'Testing create_person, update_person, delete_person' => sub {
    my $cp = $nb->create_person($test_user);
    cmp_deeply $test_user, subhashof($cp),
        "create person @{[$cp->{id}]}"
        or diag explain $cp;

    $test_user->{email} = 'test2@gmail.com';
    my $up = $nb->update_person($cp->{id}, $test_user);
    cmp_deeply $test_user, subhashof($up),
        "update person @{[$cp->{id}]}"
        or diag explain $up;

    $test_user->{phone} = '999-876-5432';
    my $pp = $nb->push_person($test_user);
    cmp_deeply $test_user, subhashof($pp),
        "push person @{[$cp->{id}]}"
        or diag explain $pp;

    ok $nb->delete_person($cp->{id}),
        "delete person @{[$cp->{id}]}";
    is $nb->get_person($cp->{id}) => 0,
        "no person @{[$cp->{id}]}";
};

subtest 'Testing set_tag, get_person_tags' => sub {
    for my $p (@{$nb->get_people}) {
        my $set_tag = $nb->set_tag($p->{id}, $test_tag);
        my $expected_tag = { person_id => $p->{id}, tag => $test_tag };
        cmp_deeply $set_tag, $expected_tag,
            "set tag \"$test_tag\" for person @{[$p->{id}]}"
            or diag explain $set_tag;
        my $get_person_tags = $nb->get_person_tags($p->{id});
        cmp_bag $get_person_tags, [$expected_tag],
            "get tag \"$test_tag\" for person @{[$p->{id}]}"
            or diag explain $get_person_tags;
    }
};

subtest 'Testing get_tags' => sub {
    for (@page_totals) {
        ok $nb->get_tags({per_page => $_}),
            sprintf $page_txt, $_;
    }

    my $all_tags = $nb->get_tags;
    cmp_deeply $all_tags, superbagof({name => $test_tag}),
        "found common tag \"$test_tag\""
        or diag explain $all_tags;
};

subtest 'Testing delete_tag' => sub {
    for my $p (@{$nb->get_people}) {
        my $tags = $nb->get_person_tags($p->{id});
        for my $tag (@$tags) {
            ok $nb->delete_tag($p->{id}, $tag->{tag}),
                "delete tag \"@{[$tag->{tag}]}\" for person @{[$p->{id}]}";
        }
        $tags = $nb->get_person_tags($p->{id});
        cmp_bag $tags, [],
            "get no tags for person @{[$p->{id}]}"
            or diag explain $tags;
    }

    my $all_tags = $nb->get_tags;
    cmp_deeply $all_tags, superbagof({name => $test_tag}),
        "found common tag \"$test_tag\""
        or diag explain $all_tags;
};

subtest 'Testing match_person' => sub {
    for my $p (@{$nb->get_people}) {
        my $match_params = {};
        my @matches = qw(email first_name last_name phone mobile);
        for (@matches) {
            $match_params->{$_} = $p->{$_} if $p->{$_};
        }
        my $mp = $nb->match_person($match_params);
        cmp_deeply $mp, superhashof($p),
            "found matching person @{[$p->{email}]}"
            or diag explain $mp;
    }

    is $nb->match_person => undef,
        'unmatched person undef';

    is $nb->match_person({email => $max_id}) => undef,
        "unmatched person $max_id";
};

subtest 'Testing get_person' => sub {
    for my $p (@{$nb->get_people}) {
        my $mp = $nb->get_person($p->{id});
        cmp_deeply $mp, superhashof($p),
            "found identified person @{[$p->{id}]}"
            or diag explain $mp;
    }

    dies_ok { $nb->get_person }
        'id param missing';

    is $nb->get_person($max_id) => 0,
        "no person $max_id";
};

subtest 'Testing get_people' => sub {
    for (@page_totals) {
        ok $nb->get_people({per_page => $_}),
            sprintf $page_txt, $_;
    }
};

subtest 'Testing get_sites' => sub {
    is $nb->get_sites->[0]{slug}, $params{subdomain},
        'nationbuilder slug matches subdomain';

    for (@page_totals) {
        ok $nb->get_sites({per_page => $_}),
            sprintf $page_txt, $_;
    }
};

done_testing;
