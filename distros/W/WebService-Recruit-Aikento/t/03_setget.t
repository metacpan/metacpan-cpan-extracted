#
# Test case for WebService::Recruit::Aikento
#

use strict;
use Test::More tests => 9;

BEGIN { use_ok('WebService::Recruit::Aikento'); }

my $obj = new WebService::Recruit::Aikento();
ok( ref $obj, 'new WebService::Recruit::Aikento()');

$obj->add_param( key => 'XXXXXXXX' );
is( $obj->get_param( 'key' ), 'XXXXXXXX', '$obj->add_param()' );

$obj->add_param( key1 => 'key1_value', key2 => 'key2_value' );
is( $obj->get_param( 'key1' ), 'key1_value', '$obj->add_param(...)' );
is( $obj->get_param( 'key2' ), 'key2_value', '$obj->add_param(...)' );

ok( $obj->user_agent, 'user_agent (default)' );
my $user_agent = $0;
$obj->user_agent( $user_agent );
is( $obj->user_agent, $user_agent, 'user_agent' );

my $utf8_flag = 1;
$obj->utf8_flag( $utf8_flag );
is( $obj->utf8_flag, $utf8_flag, 'utf8_flag (true)' );

$utf8_flag = 0;
$obj->utf8_flag( $utf8_flag );
is( $obj->utf8_flag, $utf8_flag, 'utf8_flag (false)' );

1;
