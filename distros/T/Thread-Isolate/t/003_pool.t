#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 10 } ;

use Thread::Isolate::Pool ;

use strict ;
use warnings qw'all' ;

#########################
{

  my $pool = Thread::Isolate::Pool->new()->copy ;
  
  $pool->main_thread->eval(q`
    sub test {
      for(1..5) {
        print "# " . threads->self->tid . " >>>> $_\n" ;
        threads->yield ;
        sleep(1) ;
      }
      return 10 ;
    }
  `);
  
  print "----------------------------------------------\n" ;
  my $job1 = $pool->call_detached('test') ; print "#>> $job1 [". ok(!$job1->is_no_lock) ."]\n" ;
  my $job2 = $pool->call_detached('test') ; print "#>> $job2 [". ok(!$job2->is_no_lock) ."]\n" ;
  my $job3 = $pool->call_detached('test') ; print "#>> $job3 [". ok(!$job3->is_no_lock) ."]\n" ;
  print "----------------------------------------------\n" ;


  print "<<<<<<<<<<<<<<<<\n" ;
  $job1->wait_to_start ;
  $job2->wait_to_start ;
  $job3->wait_to_start ;
  print ">>>>>>>>>>>>>>>>\n" ;
  
  my @i ;
  while( $job1->is_running || $job2->is_running || $job3->is_running ) {
    print '#' . ++$i[1] . "\n" if $job1->is_running  ;
    print '#' . ++$i[2] . "\n" if $job2->is_running  ;
    print '#' . ++$i[3] . "\n" if $job3->is_running  ;
    select(undef ,undef ,undef , 0.5) ;
  }
  
  ok( $i[1] ) ;
  ok( $i[2] ) ;
  ok( $i[3] ) ;  
  
  ok( $job1->returned , 10 ) ;
  ok( $job2->returned , 10 ) ;
  ok( $job3->returned , 10 ) ;  
  
  ok( $pool->shutdown ) ;

}
#########################

print "\nThe End! By!\n" ;

1 ;
