use WebService::Stripe;
use Test::Modern;

subtest "Default Header Values" => sub {
    my $stripe = WebService::Stripe->new(api_key => 'foo');
    like $stripe->ua->default_header('Authorization'), qr/^Basic.*$/,
        '... Uses HTTP Basic Auth';
    is $stripe->ua->default_header('Stripe-Version'), '2014-11-05',
        '... Stripe-Version header defaults to "2014-11-05"';
};

done_testing;
