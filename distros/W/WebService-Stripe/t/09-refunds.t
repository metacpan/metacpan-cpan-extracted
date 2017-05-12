use Test::Modern;
use t::lib::Common qw(skip_unless_has_secret stripe :constants);
use JSON;

skip_unless_has_secret;

my $customer = stripe->create_customer({ description => 'foo' });
my $card = stripe->create_card(
    {
        'card[number]'    => STRIPE_CARD_VISA,
        'card[exp_month]' => 12,
        'card[exp_year]'  => 2020,
    },
    customer_id => $customer->{id}
);

subtest 'refund a hold' => sub {
    my $charge = stripe->create_charge({
        amount      => 1000,
        card        => $card->{id},
        currency    => 'USD',
        customer    => $customer->{id},
        capture     => 'false',
    });
    cmp_deeply $charge,
        TD->superhashof({ amount => 1000, captured => JSON::false }),
        'created hold';
    my $refund = stripe->refund_charge($charge->{id});
    cmp_deeply $refund, TD->superhashof({amount => 1000, id => TD->re('^re')}),
        'created refund';
};

subtest 'refund a debit' => sub {
    my $charge = stripe->create_charge({
        amount      => 1000,
        card        => $card->{id},
        currency    => 'USD',
        customer    => $customer->{id},
        capture     => 'true',
    });
    cmp_deeply $charge,
        TD->superhashof({ amount => 1000, captured => JSON::true }),
        'created hold';
    my $refund = stripe->refund_charge($charge->{id});
    cmp_deeply $refund, TD->superhashof({amount => 1000, id => TD->re('^re')}),
        'created refund';
};

subtest 'refund app_fee ' => sub {
    my $account = stripe->create_account({ managed => 'true' });
    my $charge = stripe->create_charge({
        amount          => 1000,
        card            => $card->{id},
        currency        => 'USD',
        customer        => $customer->{id},
        capture         => 'true',
        application_fee => 200,
        destination     => $account->{id},
    });
    my $refund = stripe->refund_app_fee($charge->{application_fee});
    cmp_deeply $refund,
        TD->superhashof({
            amount => 200,
            id     => TD->re('^fr_'),
            object => 'fee_refund',
        }),
        'created app refund properly';
};

done_testing;
