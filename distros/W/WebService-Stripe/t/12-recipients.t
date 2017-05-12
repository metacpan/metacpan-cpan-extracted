use Test::Modern;
use t::lib::Common qw(skip_unless_has_secret stripe :constants);

skip_unless_has_secret;

subtest 'basic stuff' => sub {
    my $rcp = stripe->create_recipient(
        { name => 'foo bar', type => 'individual' }
    );
    is $rcp->{name}, 'foo bar', '... Created a new recipient w/name';
    is $rcp->{type}, 'individual', '... Created a new recipient w/type';

    $rcp = stripe->get_recipient($rcp->{id});
    is $rcp->{name}, 'foo bar', '... Fetched the created recipient';
};

subtest 'recipient with card' => sub {
    my $rcp = stripe->create_recipient({
        name => 'foo bar',
        type => 'individual',
        card => {
            number    => STRIPE_CARD_VISA,
            exp_month => 12,
            exp_year  => 2020,
        }
    });

    is $rcp->{name}, 'foo bar', '... Created a new recipient w/name';
    is @{$rcp->{cards}{data}}, 1, '... Recipient has 1 card';
    like $rcp->{default_card} => qr/card_.*/, '... Recipient has 1 card';
};

done_testing;
