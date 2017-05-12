#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 3 } ;

use Thread::Isolate ;

use strict ;
use warnings qw'all' ;

#########################
{
  
  $|=1 ;
  
  my $thi = Thread::Isolate->new() ;
  
  $thi->add_standby_eval(q`
    $thi = Thread::Isolate->self ;
    $thi->self->set_attr('count_standby' , $thi->get_attr('count_standby') + 1 ) ;
    print "# STAND BY!\n" ;
  `) ;
  
  for my $i (1..10) {
    print "...\n" ;
    if ( $i == 5 ) {
      $thi->eval(q`
        Thread::Isolate->self->set_attr('new_job' , 1 ) ;
        print "# NEW JOB!\n" ;
     `) ;
    }
    sleep(1);
  }
  
  ok( $thi->get_attr('count_standby') >= 3 ) ;
  
  ok( $thi->get_attr('new_job') , 1 ) ;
  
  ok( $thi->shutdown ) ;  

}
#########################

print "\nThe End! By!\n" ;

1 ;

