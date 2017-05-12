#!/usr/bin/perl
use strict;

my $data= {};






my ($CODE,$POD,$structure_data);

for my $method ( keys %$data ){
   my $val = $data->{$method};

   my $type ;
   my $head=2;

   if ( ref $val eq 'HASH'  ){
      $type = 'hash ref';

      $strucure_data->{$method}={};

   }
   elsif( ref $val eq 'ARRAY'){
      $type = 'array ref'; 
   
      $structure_data->{$method}=[];

   }

   elsif( $val =~/http/ ){
      $type = 'url string';
      $structure_data->{$method} = undef;
   }

   elsif ( $val =~/^[01]$/{
      $type = 'boolean';
      $structure_data->{$method} = undef;

   }

   else {
      $type = 'string';
      $structure_data->{$method} = undef;

   }



      

}



# this really would have to later be the code analizer
#
#
#



