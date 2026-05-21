#!perl
use Test::More tests => 5;
use WWW::Vonage::API;
use Data::Dumper;

eval { 
    WWW::Vonage::API->new() 
    };
ok($@, 'new() dies when no parameters are provided');
like($@, qr/API_Key|API_Secret/i, 'Error message mentions missing parameters');

eval { 
    WWW::Vonage::API->new( API_Key => 'dummy_key_123' ) 
};

ok($@, 'new() dies when API_Secret is missing');

eval { 
    WWW::Vonage::API->new( API_Secret => 'dummy_secret_456' ) 
};
ok($@, 'new() dies when API_Key is missing');

my $api;
eval { 
    $api = WWW::Vonage::API->new(
        API_Key    => 'dummy_key_123',
        API_Secret => 'dummy_secret_456',
    ) 
};
is($@, '', 'new() lives (does not die) when both API_Key and API_Secret are provided');

  $api = WWW::Vonage::API->new(
        API_Key    => 'dummy_key_new',
        API_Secret => 'dummy_secret_new',
    );
    
