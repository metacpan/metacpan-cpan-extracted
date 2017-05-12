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

   my $w = WordPress::Post->new($conf);

   ok($w,'object initiated');





   my $image = './t/image.jpg';

   my $url = $w->post_file(
      $image,
   );
   ok(1,'image posting didnt die');
   ok($url," got url $url");

}





