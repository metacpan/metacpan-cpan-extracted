use Test::Modern;
use t::lib::Common qw(:constants skip_unless_has_secret stripe);

skip_unless_has_secret;

subtest 'get_platform_account' => sub {
    my $account = stripe->get_platform_account;
    cmp_deeply $account => TD->superhashof({
        id     => TD->re('\w'),
        object => 'account',
    });
};

done_testing;
