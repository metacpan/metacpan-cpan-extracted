use Test::Simple 'no_plan';
use strict;
use lib './lib';

use WordPress::Post;

use WordPress::CLIDeprecated;


ok(1,'starting test.');


if( ! -f './t/wppost' ){
   ok(1,'To test fully, you need to set up a ./t/wppost YAML file as per instructions in WordPress::CLI');
}
else {

   my $conf = WordPress::CLIDeprecated::_conf('./t/wppost');
   ok(1,'got testing conf ./t/wppost');

   ### $conf

   

   my $w = WordPress::Post->new($conf);

   ### $w

   ok($w,'object initiated');

   ok( $w->proxy, 'proxy method returns') or die('check your conf');
   ok( $w->password, 'password method returns');
   ok( $w->username, 'username method returns');

   my $categories =  $w->categories;
   ok( ref $categories eq 'ARRAY','categories returns array ref');
   ok(scalar @$categories, "categories has at least one  entry") or die;


   map { ok($_," category: $_") }  @$categories;




   ok(
   $w->post({
      title => ('test_'.time()),
      description => 'test description here' ,
   })

   , 'posted') or die;


}






