#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 1 } ;

use lib::http ;

use strict ;
use warnings qw'all' ;

#########################
{
  ok(1) ;
}
#########################

print "\nThe End! By!\n" ;

1 ;
