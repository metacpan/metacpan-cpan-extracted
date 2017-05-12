use Test::Modern;
use t::lib::Common qw(skip_unless_has_secret stripe);

skip_unless_has_secret;

subtest "Balance for the Stripe marketplace" => sub {
    my $bal = stripe->get_balance;
    cmp_deeply $bal, TD->superhashof({ object => 'balance' }),
        '... Fetched balance'
        or diag explain $bal;
};

done_testing;
