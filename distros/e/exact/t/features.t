use Test2::V0;
use exact qw( nobundle switch state noswitch );

ok( warns { eval 'say 42' }, 'say include skipped' );
ok( lives { state $x }, 'state included ok' ) or note $@;

done_testing;
