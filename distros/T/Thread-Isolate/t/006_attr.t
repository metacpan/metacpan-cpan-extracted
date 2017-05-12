#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 9 } ;

use Thread::Isolate ;

use strict ;
use warnings qw'all' ;

#########################
{
  
  my $thi = Thread::Isolate->new() ;
  
  my $job = $thi->eval_detached(q`
    my $thi = Thread::Isolate->self ;

    for(1..5) {
      my $val = $thi->get_attr('count') || 0 ;
      my $count = $thi->set_attr('count' , $val + 1) ;
      $thi->set_global('count' , $thi->get_global('count') . "$count;") ;
      print "# thread> $count\n" ;
      1 while( $count < 10 && $thi->get_attr('count') < $count + 1 ) ;
    }
  `) ;
  
  ok($job) ;
  
  for my $i (1..5) {
    my $val = $thi->get_attr('count') || 0 ;
    my $count = $thi->set_attr('count' , $val + 1) ;
    ok( $thi->get_attr('count') , ($i*2)-1 ) ;
    print "#   main> $count [$i]\n" ;
    1 while( $count < 10 && $thi->get_attr('count') < $count + 1 ) ;
  }
  
  ok( $thi->get_attr('count') , 10 ) ;
  
  my $thi2 = Thread::Isolate->new() ;
  
  ok( $thi2->get_global('count') , '2;4;6;8;10;' ) ;
  
  $job = undef ;
  
  ok( $thi->shutdown ) ;  

}
#########################

print "\nThe End! By!\n" ;

1 ;

