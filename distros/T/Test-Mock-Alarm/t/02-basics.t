use Test::Exception;
use Test::More tests => 3;

use Test::Mock::Alarm qw(set_alarm restore_alarm);

## override the built-in alarm
set_alarm( sub { die 'you gave the alarm: ' . (shift) } );

dies_ok( sub { alarm(20) }, 'alarm replaced with "die" dies' );
like( $@, '/^you gave the alarm: 20/', 'replaced alarm behaves properly' );

## reset it
restore_alarm();
lives_ok( sub { alarm(20) }, 'alarm is restored' );
