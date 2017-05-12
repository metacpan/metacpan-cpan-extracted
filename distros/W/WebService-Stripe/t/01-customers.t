use Test::Modern;
use t::lib::Common qw(skip_unless_has_secret stripe);

skip_unless_has_secret;

subtest 'basic stuff' => sub {
    my $cust = stripe->create_customer({ description => 'foo' });
    is $cust->{description}, 'foo',
        '... Created a new customer w/custom description';

    $cust = stripe->get_customer($cust->{id});
    is $cust->{description}, 'foo',
        '... Fetched the created customer';

    $cust = stripe->update_customer(
        $cust->{id}, data=> { description => 'bar' });
    is $cust->{description}, 'bar',
        '... Updated the customer';

    $cust = stripe->get_customer($cust->{id});
    is $cust->{description}, 'bar',
        '... Update persisted when customer re-fetched';
};

subtest 'create customer with no data' => sub {
    my $cust = stripe->create_customer({});
    ok $cust->{id},
        '... Created a customer with no data';
};

subtest 'Add a funding source to a customer' => sub {
    my $cust = stripe->create_customer({});
    my $card = stripe->add_source($cust, {
        "source[object]"    => "card",
        "source[exp_month]" => "12",
        "source[exp_year]"  => "2020",
        "source[number]"    => ("4242" x 4),
        "source[cvc]"       => "123",
    });
    like $card->{id}, qr/^card_\w+/,
        '... Added a card to the user';
};

done_testing;
