use warnings;
use strict;

use Test::More;
use Data::Dumper;

plan skip_all => '$ENV{API_KEY} NOT SET' unless $ENV{API_KEY};

require_ok( 'WebService::FaucetBOX' );

isa_ok(
  my $faucetbox = WebService::FaucetBOX->new(
    api_key => $ENV{API_KEY},
  ) => 'WebService::FaucetBOX' => '$faucetbox'
);

my $balance;

isa_ok( $balance = $faucetbox->getBalance => 'HASH' => '$balance' );

diag( Data::Dumper->Dump([$balance], ['balance']) ) if $ENV{VERBOSE};

isa_ok( $balance = $faucetbox->getBalance( options => { currency => 'BTC' }) => 'HASH' => '$balance' );

diag( Data::Dumper->Dump([$balance], ['balance']) ) if $ENV{VERBOSE};

isa_ok( my $currencies = $faucetbox->getCurrencies => 'HASH' => '$currencies' );

diag( Data::Dumper->Dump([$currencies], ['currencies']) ) if $ENV{VERBOSE};

isa_ok( my $send = $faucetbox->send( DEADBEEF => 100 ) => 'HASH' => '$send' );

diag( Data::Dumper->Dump([$send], ['send']) ) if $ENV{VERBOSE};

done_testing();
