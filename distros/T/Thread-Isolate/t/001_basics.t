#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 8 } ;

use Thread::Isolate ;

use strict ;
use warnings qw'all' ;

#########################
{
  ok(1) ;
}
#########################
{

  my $thi = Thread::Isolate->new() ;
  
  ok( $thi->eval(' 2**10 ')  , 1024 );

}
#########################
{

  my $thi = Thread::Isolate->new() ;
  
  $thi->eval(q`
    sub TEST {
      my ( $var ) = @_ ;
      return $var ** 10 ;
    }
  `) ;
  
  ok( $thi->call('TEST' , 2)  , 1024 );  
  ok( $thi->call('TEST' , 3)  , 59049 );  
  ok( $thi->call('TEST' , 4)  , 1048576 );

}
#########################
{

  my $thi = Thread::Isolate->new() ;
  
  $thi->use('Data::Dumper') ;
  
  ok( !$thi->err ) ;
  
  my $dump = $thi->call('Data::Dumper::Dumper' , [123 , 456 , 789]) ;
  
  $dump =~ s/\s+/ /gs ;
  
  ok($dump , '$VAR1 = [ 123, 456, 789 ]; ') ;

  ok( !$INC{'Data/Dumper.pm'} ) ;

}
#########################

print "\nThe End! By!\n" ;

1 ;
