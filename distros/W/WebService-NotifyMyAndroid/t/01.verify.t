use strict;
use warnings;

use Test::More tests => 3;                      # last test to print

BEGIN { use_ok( 'WebService::NotifyMyAndroid' ); }

use Data::Dumper;

my $APIKEY = '67f9b6dbd5cc00f245ff677e288f4e3aecc97f49cbf3b2a3';

my $nma = WebService::NotifyMyAndroid->new;

my( $verify ) = $nma->verify( apikey => $APIKEY );

ok( $verify->{success}->{code} == 200, 'API accepts valid key' );

$verify = $nma->verify( apikey => 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef' );

ok( $verify->{error}->{code} == 401, 'API rejects valid but nonexistent key' );
