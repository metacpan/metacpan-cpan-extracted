#!/usr/bin/perl 

use strict;
use warnings;

use Test::Most qw{no_plan};
#use Carp::Always;

#-----------------------------------------------------------------
#  
#-----------------------------------------------------------------
BEGIN {

   print qq{\n} for 1..10;
   use_ok('Util::Timeout');
   can_ok('main', qw{
      timeout
      retry
   });

};
#-----------------------------------------------------------------
#  
#-----------------------------------------------------------------

ok(!timeout 1 { sleep(2) }, q{inverted return});
ok( timeout 2 { 1 }, q{inverted return} );
is( (timeout 1 { sleep(2) } or 'hello'), 'hello', q{catch} );

ok( my $num = 1 );
is( $num, 1);

timeout 2 { $num++;sleep(1); } or do { $num = 0 };

is( $num, 2, q{side effects are not rolled back} );

timeout 1 { $num++;sleep(2); } or do { $num = 0 };

is( $num, 0, q{proof of catch case} );

ok(!timeout 0.5 { sleep(20)   } ,q{decimal seconds rounded up, still catch} );
ok( timeout 0.5 { sleep(0.1) } , q{decimal seconds rounded up, still catch} );

ok(!timeout 0 { 'hello' }, q{zero always fails});

#---------------------------------------------------------------------------
#  Retry
#---------------------------------------------------------------------------
$num = 3;
retry 5 { timeout 1 { sleep($num--) } } or $num = 'FAIL';
is( $num, -1, q{success});
$num = 10;
retry 5 { timeout 1 { sleep($num--) } } or $num = 'FAIL';
is( $num, 'FAIL',  q{correctly bailed on the retry});




