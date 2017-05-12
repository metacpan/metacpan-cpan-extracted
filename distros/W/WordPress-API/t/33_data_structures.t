use Test::Simple 'no_plan';
use strict;
use lib './lib';

use WordPress::Base::Data::Page; 
use WordPress::Base::Data::Category; 
use WordPress::Base::Data::Author; 
use WordPress::Base::Data::Post;
use WordPress::Base::Data::MediaObject; 
#use Smart::Comments '###';

ok(1,'starting test.');


for my $otype(   qw(Page Post MediaObject Author Category) ){
   my $mname = "WordPress::Base::Data::$otype";

   my $o = new $mname;
   ok($o,"instanced $mname");

   ### calling.... 
   my $struct = $o->structure_data;
   
   ### $struct


   ok($struct,'got back structure_data');
   ok( ref $struct eq 'HASH','got hash ref');

   $o->structure_data_set(); # this should be there for now, will deprecate
}



