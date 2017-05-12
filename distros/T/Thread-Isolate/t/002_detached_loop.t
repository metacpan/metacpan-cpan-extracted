#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 3 } ;

use Thread::Isolate ;

use strict ;
use warnings qw'all' ;

#########################
{

  my $thi = Thread::Isolate->new() ;
  
  my $job = $thi->eval_detached(q`
    for(1..10) {
      print "in> $_\n" ;
      threads->yield ;
      sleep(1);
    }
    return 2**3 ;
  `);
  
  sleep(1);
  
  $job->wait_to_start ;
  
  my $i ;
  while( $job->is_running ) {
    ++$i ;
    print "out> $i\n" ;
    sleep(1);
  }
  
  ok($i >= 1) ;
  
  ok( $job->returned , 8 ) ;
  
  $job = undef ;
  
  ok( $thi->exists ) ;

}
#########################

print "\nThe End! By!\n" ;

1 ;
