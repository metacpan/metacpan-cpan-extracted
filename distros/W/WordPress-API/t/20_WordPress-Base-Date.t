use Test::Simple 'no_plan';
use lib './lib';
ok(1,'skipped') and exit;
#use WordPress::Base::Date ':all';
#use Smart::Comments '###';


my @datestrings = qw(20080205T13:21:31 20080205T21:02:00 19791205T00:06:40 20070731T02:46:00);

my $made = time2datestring(time());

ok($made, " NOW IS $made") or die;





for my $string ( @datestrings ){

   print STDERR "\n #--------------------- $string ----\n";

   my $parse= datestring_parse($string);
 
   ok($parse," parsed $string") or die;

   my $time = datestring2time($string);
 
   my $made = time2datestring($time);
   
   ok( datestring_ok($made),'datestring made is ok '.$made); 

  
   ### $time
   ### $parse
   ### $made
  

}

