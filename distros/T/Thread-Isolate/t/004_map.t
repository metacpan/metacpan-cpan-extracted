#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 5 } ;

use Thread::Isolate::Map ;

use strict ;
use warnings qw'all' ;

#########################
{
  
  $|=1 ;
  
  my $thi = Thread::Isolate->new() ;
  $thi->eval(q`
    package Foo ;
      $FOOVAL = 0 ;
  `) ;

  my $thi1 = Thread::Isolate->new() ;
  my $thi2 = Thread::Isolate->new() ;
  
  $thi1->map_package('Foo',$thi) ;
  $thi2->map_package('Foo',$thi) ;
  
  my $ret1 = $thi1->eval('$Foo::FOOVAL = 10 ; return $Foo::FOOVAL * 3 ;');

  ok( $ret1 , 30 ) ;

  my $ret2 = $thi2->eval('$Foo::FOOVAL += 10 ; return $Foo::FOOVAL * 2 ;');

  ok( $ret2 , 40 ) ;
  
  ok( $thi1->shutdown ) ;
  ok( $thi2->shutdown ) ;
  ok( $thi->shutdown ) ;  

}
#########################

print "\nThe End! By!\n" ;

1 ;

