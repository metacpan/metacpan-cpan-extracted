use Test::Modern;
use t::lib::Harness qw(lob);
plan skip_all => 'LOB_API_KEY not in ENV' unless defined lob();

subtest 'Testing get_states' => sub {
    my $states = lob->get_states;
    ok $states,
        "successfully retreived @{[~~@$states]} states"
        or diag explain $states;
};

subtest 'Testing get_countries' => sub {
    my $countries = lob->get_countries;
    ok $countries,
        "successfully retreived @{[~~@$countries]} countries"
        or diag explain $countries;
};

done_testing;
