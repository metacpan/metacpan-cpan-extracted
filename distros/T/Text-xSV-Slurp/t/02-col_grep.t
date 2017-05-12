use warnings;
use strict;

use Test::More tests => 4;

use Text::xSV::Slurp;

my @tests =
   (

   {
   
   id => 'aoa',

   in => <<EOIN,
a,b,c
1,2,3
4,5,6
EOIN

   exp => 
      [ ['b'], ['2'], ['5'] ],
      
   opts =>
      {
      shape    => 'aoa',
      col_grep => sub { grep { $_ % 2 } @_ },
      },

   },

   {
   
   id => 'aoh',

   in => <<EOIN,
a,b,c
1,2,3
4,5,6
EOIN

   exp => 
      [
      { a => 1, c => 3 },
      { a => 4, c => 6 },
      ],
      
   opts =>
      {
      shape    => 'aoh',
      col_grep => sub { grep { /[ac]/ } @_ },
      },

   },

   {
   
   id => 'hoa',

   in => <<EOIN,
a,b,c
1,2,3
4,5,6
EOIN

   exp => 
      {
      b => [ 2, 5 ],
      c => [ 3, 6 ],
      },
      
   opts =>
      {
      shape    => 'hoa',
      col_grep => sub { grep { /[bc]/ } @_ },
      },

   },

   {
   
   id => 'hoh',

   in => <<EOIN,
a,b,c,d
1,2,3,7
4,5,6,8
EOIN

   exp => 
      {
      2 => { 3 => { d => 7 } },
      5 => { 6 => { d => 8 } },
      },
      
   opts =>
      {
      shape    => 'hoh',
      col_grep => sub { grep { /d/ } @_ },
      key      => 'b,c',
      },

   },

   );

for my $test ( @tests )
   {
   my $got = xsv_slurp( string => $test->{'in'}, %{ $test->{'opts'} } );
   my $exp = $test->{'exp'};
   my $id  = $test->{'id'};
   is_deeply($got, $exp, $id);
   }
