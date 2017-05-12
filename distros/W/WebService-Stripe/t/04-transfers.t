use Test::Modern qw(:deeper :fatal :more);
use t::lib::Common qw(:constants skip_unless_has_secret stripe);
use JSON qw(from_json);

skip_unless_has_secret;

my $account = stripe->create_account({
    managed => 'true',
    country => 'CA',
});
my $bank = stripe->add_bank(
    {
        'bank_account[country]'        => 'CA',
        'bank_account[currency]'       => 'cad',
        'bank_account[routing_number]' => STRIPE_BANK_CA_ROUTING_NO,
        'bank_account[account_number]' => STRIPE_BANK_ACCOUNT,
    },
    account_id => $account->{id},
);
cmp_deeply $bank => superhashof({ last4 => 6789 }), 'created bank';

subtest 'create a transfer and do stuff with it' => sub {
    my $transfer = stripe->create_transfer({
        amount      => 100,
        currency    => 'cad',
        destination => $account->{id},
    });
    cmp_deeply $transfer => superhashof({
        id     => re('^tr_'),
        amount => 100,
    }),
        '... Created a transfer';

    my $transfer_id = $transfer->{id};
    $transfer = stripe->update_transfer($transfer->{id}, data => {
        'metadata[foo]' => 'bar'
    });
    is $transfer->{id}, $transfer_id,
        '... Updated a transfer';

    $transfer = stripe->get_transfer($transfer->{id});
    cmp_deeply $transfer => superhashof({
        id       => $transfer_id,
        amount   => 100,
        metadata => { foo => 'bar' },
    }),
        '... Got an existing transfer';

    # Expect failure b/c Stripe's test env doesn't support this
    my $err = exception { stripe->cancel_transfer($transfer->{id}) };
    like $err, qr/while they are pending/,
        '... Sent cancel request to Stripe';
};

subtest 'list transfers' => sub {
    my $transfers = stripe->get_transfers;
    ok $transfers->{data}[0]{amount};
};

subtest 'reverse_transfer' => sub {
    subtest "Can create a complete reversal" => sub {
        my $xfer = stripe->create_transfer({
            amount             => 100,
            currency           => 'cad',
            destination        => $account->{'id'},
            'metadata[tester]' => 'WebService::Stripe::reverse_transfer',
        });

        my $reversal = stripe->reverse_transfer($xfer->{'id'});
        cmp_deeply $reversal, superhashof({
            object => 'transfer_reversal',
            amount => 100,
        }),
            '... Created a full reversal',
            or diag explain $reversal;
    };

    subtest "Can create a partial reversal" => sub {
        my $xfer = stripe->create_transfer({
            amount      => 50,
            currency    => 'cad',
            destination => $account->{'id'},
        });

        my $reversal = stripe->reverse_transfer($xfer->{'id'},
            data => {
                amount => 25,
            }
        );
        cmp_deeply $reversal, superhashof({
            object => 'transfer_reversal',
            amount => 25,
        }),
            '... Created a 50% reversal',
            or diag explain $reversal;
    };

    subtest "Can reverse an Account-scoped bank transfer" => sub {
        my $xfer = stripe->create_transfer({
            amount      => 50,
            currency    => 'cad',
            destination => $bank->{'id'},
        }, headers => { stripe_account => $account->{'id'} });

        my $err = exception {
            stripe->reverse_transfer($xfer->{'id'},
                data => {
                    amount => 25,
                },
                headers => {
                    stripe_account => $account->{'id'}
                }
            );
        };

        # Expect failure b/c Stripe's test environment doesn't support this
        like $err, qr/while they are pending/,
            '... Sent reversal request to Stripe';
    };
};

done_testing;
