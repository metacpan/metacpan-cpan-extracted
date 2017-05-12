use strict;
use warnings;

use Test::More;
use Test::Exception;

use WebService::Affiliate::Merchant;

my $merchant;

lives_ok { $merchant = WebService::Affiliate::Merchant->new } "instantiated empty merchant ok";

ok( $merchant->id eq '', "no id yet" );
ok( $merchant->name eq '', "no name yet" );

lives_ok { $merchant = WebService::Affiliate::Merchant->new( id => 7, name => 'ASDA' ) } "instantiated full merchant ok";

ok( $merchant->id == 7, "id is 7" );
ok( $merchant->name eq 'ASDA', "name is ASDA" );

lives_ok { $merchant->id( 9 ) } "update id to 9 ok";

ok( $merchant->id == 9, "id is 9" );
ok( $merchant->name eq 'ASDA', "name is still ASDA" );

lives_ok { $merchant->name( 'Tesco' ) } "update name to Tesco ok";

ok( $merchant->id == 9, "id is 9" );
ok( $merchant->name eq 'Tesco', "name is now Tesco" );





done_testing();
