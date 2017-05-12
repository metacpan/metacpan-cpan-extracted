use Test::Modern;
use t::lib::Common qw(skip_unless_has_secret stripe :constants);
use JSON;

skip_unless_has_secret;

my $customer = stripe->create_customer({ description => 'foo' });
my $card = stripe->create_card(
    {
        card => {
            number    => STRIPE_CARD_VISA,
            exp_month => 12,
            exp_year  => 2020,
        }
    },
    customer_id => $customer->{id}
);

subtest 'create charge' => sub {
    my $charge = stripe->create_charge({
        amount      => 1000,
        card        => $card->{id},
        currency    => 'USD',
        customer    => $customer->{id},
        capture     => 'true',
        description => 'foo',
    });
    cmp_deeply $charge,
        TD->superhashof({
            amount      => 1000,
            description => 'foo',
            captured    => JSON::true,
        }),
        'created charge';

    $charge = stripe->get_charge($charge, query => { expand => ['customer'] });
    cmp_deeply $charge->{customer}, TD->superhashof({
        object => 'customer',
        id     => $customer->{id},
    }),
        '... Fetched the charge with expanded "customer" relation';

    $charge = stripe->update_charge($charge, data => {
        description     => 'Foobar',
        'metadata[bar]' => 'baz',
    });
    cmp_deeply $charge, TD->superhashof({
        description => 'Foobar',
        metadata    => { bar => 'baz' },
    }),
        '... Updated charge data';
};

done_testing;
