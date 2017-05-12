# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#########################
# change 'tests => 1..2' to 'tests => last_test_to_print';
use Test::More; 

eval {$ARGV[0]= '-Test.pm Syntax test';
      require 'scripts/viewer.pl' };

if( $@ ) {
    plan skip_all => "Failure to access X-terminal, Bad configuration assumed" ;
         }
 else {
    plan tests => 1;
   }

   ok(! $@, "Syntax check"); 
#########################
