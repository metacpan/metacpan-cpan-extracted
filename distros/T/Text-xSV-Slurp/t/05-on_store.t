use warnings;
use strict;

use Test::More tests => 6;

use Text::xSV::Slurp;

my @tests =
   (

   {
   
   id => 'count',

   in => <<EOIN,
a,b,c
1,2,3
1,2,3
1,2,3
1,2,4
1,2,4
1,2,5
EOIN

   exp => 
      {
      1 => { 3 => { b => 3 }, 4 => { b => 2 }, 5 => { b => 1 } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', on_store => 'count' },

   },

   {
   
   id => 'frequency',

   in => <<EOIN,
a,b,c
1,2,3
1,2,3
1,4,3
1,4,3
1,4,3
EOIN

   exp => 
      {
      1 => { 3 => { b => { 2 => 2, 4 => 3 } } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', on_store => 'frequency' },

   },

   {
   
   id => 'push collide',

   in => <<EOIN,
a,b,c
1,2,3
1,4,3
1,2,5
EOIN

   exp => 
      {
      1 => { 3 => { b => [2,4] }, 5 => { b => [2] } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', on_store => 'push' },

   },

   {
   
   id => 'unshift collide',

   in => <<EOIN,
a,b,c
1,2,3
1,4,3
1,2,5
EOIN

   exp => 
      {
      1 => { 3 => { b => [4,2] }, 5 => { b => [2] } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', on_store => 'unshift' },

   },

   {
   
   id => 'by key - all',

   in => <<EOIN,
a,b,count,frequency,push,unshift
1,2,3,1,2,3
1,4,3,1,2,3
1,2,5,1,2,3
EOIN

   exp => 
      {
      1 => {
         2 => {
            count     => 2,
            frequency => { 1 => 2 },
            push      => [ 2, 2 ],
            unshift   => [ 3, 3 ],
              },
         4 => {
            count     => 1,
            frequency => { 1 => 1 },
            push      => [ 2 ],
            unshift   => [ 3 ],
              },
           },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,b', on_store => { map { $_ => $_ } qw/ count frequency push unshift / } },

   },

   {
   
   id => 'custom count',

   in => <<EOIN,
a,b,c
1,2,3
1,2,3
1,2,3
1,2,3
1,2,3
EOIN

   exp => 
      {
      1 => { 3 => { b => 5 } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', on_store => sub { return ( $_[Text::xSV::Slurp::HOH_HANDLER_OLD_VALUE] || 0 ) + 1 } },

   },

   );

for my $test ( @tests )
   {
   my $got = xsv_slurp( string => $test->{'in'}, %{ $test->{'opts'} } );
   my $exp = $test->{'exp'};
   my $id  = $test->{'id'};
   is_deeply($got, $exp, $id);
   }
