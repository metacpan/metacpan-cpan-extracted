use warnings;
use strict;

use Test::More tests => 15;

use Text::xSV::Slurp;

my @tests =
   (

   {
   
   id => 'string, defaults',

   in => <<EOIN,
a,b,c
1,2,3
EOIN

   exp => 
      [{
      a => 1,
      b => 2,
      c => 3,
      }],
      
   opts =>
      {},

   },

   {
   
   id => 'header only, string, defaults',

   in => <<EOIN,
a,b,c
EOIN

   exp => 
      [],
      
   opts =>
      {},

   },

   {
   
   id => 'empty, string, defaults',

   in => '',

   exp => 
      [],
      
   opts =>
      {},

   },

   {
   
   id => 'string, aoh',

   in => <<EOIN,
a,b,c
1,2,3
EOIN

   exp => 
      [{
      a => 1,
      b => 2,
      c => 3,
      }],
      
   opts =>
      { shape => 'aoh' },

   },

   {
   
   id => 'header only, string, aoh',

   in => <<EOIN,
a,b,c
EOIN

   exp => 
      [],
      
   opts =>
      { shape => 'aoh' },

   },

   {
   
   id => 'empty, string, aoh',

   in => '',

   exp => 
      [],
      
   opts =>
      { shape => 'aoh' },

   },

   {
   
   id => 'string, aoa',

   in => <<EOIN,
a,b,c
1,2,3
EOIN

   exp => 
      [
         [ qw/ a b c / ],
         [ qw/ 1 2 3 / ],
      ],
      
   opts =>
      { shape => 'aoa' },

   },

   {
   
   id => 'header only, string, aoa',

   in => <<EOIN,
a,b,c
EOIN

   exp => 
      [
         [ qw/ a b c / ],
      ],
      
   opts =>
      { shape => 'aoa' },

   },

   {
   
   id => 'empty, string, aoa',

   in => '',

   exp => 
      [],
      
   opts =>
      { shape => 'aoa' },

   },

   {
   
   id => 'string, hoa',

   in => <<EOIN,
a,b,c
1,2,3
EOIN

   exp => 
      {
      a => [ 1 ],
      b => [ 2 ],
      c => [ 3 ],
      },
      
   opts =>
      { shape => 'hoa' },

   },

   {
   
   id => 'header only, string, hoa',

   in => <<EOIN,
a,b,c
EOIN

   exp => 
      {
      a => [ ],
      b => [ ],
      c => [ ],
      },
      
   opts =>
      { shape => 'hoa' },

   },

   {
   
   id => 'empty, string, hoa',

   in => '',

   exp => 
      {},
      
   opts =>
      { shape => 'hoa' },

   },

   {
   
   id => 'string, hoh',

   in => <<EOIN,
a,b,c
1,2,3
EOIN

   exp => 
      {
      1 => { 3 => { b => 2 } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c' },

   },

   {
   
   id => 'header only, string, hoh',

   in => <<EOIN,
a,b,c
EOIN

   exp => 
      {
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c' },

   },

   {
   
   id => 'empty, string, hoh',

   in => '',

   exp => 
      {},
      
   opts =>
      { shape => 'hoh', key => 'a,c' },

   },

   );

for my $test ( @tests )
   {
   my $got = xsv_slurp( string => $test->{'in'}, %{ $test->{'opts'} } );
   my $exp = $test->{'exp'};
   my $id  = $test->{'id'};
   is_deeply($got, $exp, $id);
   }