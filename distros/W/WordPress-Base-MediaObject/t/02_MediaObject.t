use Test::Simple 'no_plan';
use lib './lib';
use strict;
use WordPress::Base::MediaObject ':all';

my @f = qw(t/image.jpg);

for my $path (@f) {

   my $r;
   ok( $r = get_mime_type($path), 'get_mime_type()');
   ### $r
   ok( $r eq 'image/jpeg',"have mime type is [$r]");
   my $l = length($r);
   ok( $l, "length is $l");
   
   ok( $r = get_file_bits($path), 'get_file_bits()');
   ### $r
   $l = length($r);
   ok( $l, "length is $l");

   ok( $r = get_file_name($path), 'get_file_name()');
   ### $r
   ok( $r eq 'image.jpg' );

   $r = abs_path_to_media_object_data($path);
   ok( $r, 'abs_path_to_media_object_data()');

}




